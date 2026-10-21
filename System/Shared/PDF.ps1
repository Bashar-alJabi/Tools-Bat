# Small PDF primitives shared by the independent PDF tools. Core.ps1 is loaded first.
# All native filenames supplied here are private ASCII aliases, never user commands.
function Get-PDFCount([string]$Alias) {
    $answer=Invoke-Checked $script:PDFEngine @('-q','-dSAFER','-dPDFSTOPONERROR','-dNODISPLAY',('--permit-file-read='+$Alias),'-c',('('+$Alias+') (r) file runpdfbegin pdfpagecount = quit'))
    $n=0
    if(-not [int]::TryParse($answer.Trim(),[ref]$n) -or $n -lt 1 -or $n -gt 1000){throw 'Invalid, encrypted, damaged, or over 1000-page PDF.'}
    $n
}
function Get-PDFText([string]$Alias,[int]$Page) {
    [void](Invoke-Checked $script:PDFEngine @('-q','-dSAFER','-dPDFSTOPONERROR','-dBATCH','-dNOPAUSE','-sDEVICE=txtwrite','-dTextFormat=3',('-dFirstPage='+$Page),('-dLastPage='+$Page),'-sOutputFile=page-text.txt',$Alias))
    [IO.File]::ReadAllText((Join-Path $script:NativeWorkingDirectory 'page-text.txt'),(New-Object Text.UTF8Encoding($false,$true)))
}
function Render-PDFPage([string]$Alias,[int]$Page,[string]$Target,[int]$DPI=120) {
    [void](Invoke-Checked $script:PDFEngine @('-q','-dSAFER','-dPDFSTOPONERROR','-dBATCH','-dNOPAUSE','-dUseCropBox','-sDEVICE=png16m',('-r'+$DPI),'-dTextAlphaBits=4','-dGraphicsAlphaBits=4',('-dFirstPage='+$Page),('-dLastPage='+$Page),('-sOutputFile='+$Target),$Alias))
}
function Get-PDFSelection([string]$Text,[int]$Count) {
    if($Text -eq 'all'){return ,@(1..$Count)}
    if($Text.Length -gt 5000 -or $Text -notmatch '^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$'){throw 'Use all or a page list such as 2,5,7-10.'}
    $pages=New-Object 'Collections.Generic.List[int]'
    foreach($token in $Text.Split(',')){
        $range=$token.Split('-');$first=0;$last=0
        if(-not [int]::TryParse($range[0],[ref]$first)){throw 'Invalid page number.'}
        $last=$first
        if($range.Count -eq 2 -and -not [int]::TryParse($range[1],[ref]$last)){throw 'Invalid page range.'}
        if($first -lt 1 -or $last -lt $first -or $last -gt $Count){throw 'Page range outside document.'}
        for($n=$first;$n -le $last;$n++){if($pages.Contains($n)){throw 'Duplicate page number.'};$pages.Add($n)}
    }
    return ,$pages.ToArray()
}
function Join-PDFPages([string[]]$Aliases,[string]$Target) {
    [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'pdf-list.txt'),$Aliases,(New-Object Text.ASCIIEncoding))
    [void](Invoke-Checked $script:PDFEngine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dAutoRotatePages=/None',('-sOutputFile='+$Target),'@pdf-list.txt'))
    if((Get-PDFCount $Target) -ne $Aliases.Count){throw 'Output page count mismatch.'}
}
function Export-PDFPage([string]$Alias,[int]$Page,[string]$Target) {
    [void](Invoke-Checked $script:PDFEngine @('-q','-dSAFER','-dPDFSTOPONERROR','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dAutoRotatePages=/None',('-dFirstPage='+$Page),('-dLastPage='+$Page),('-sOutputFile='+$Target),$Alias))
}
function Read-PrivatePassword([string]$Prompt) {
    # Redirected stdin is an explicit automation interface; never accept argv/env secrets.
    if([Console]::IsInputRedirected){$value=[Console]::ReadLine();if(-not $value){throw 'No password supplied on private stdin.'};return $value}
    $secure=Read-Host $Prompt -AsSecureString
    $pointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)}
    finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer);$secure.Dispose()}
}
function Invoke-QPDFJob([string]$Executable,$Job) {
    # qpdf @- reads one argument per line from an anonymous stdin pipe.
    # --job-json-file=- does NOT read stdin in qpdf 12.4.2.
    $arguments=New-Object 'Collections.Generic.List[string]'
    $arguments.Add([string]$Job.inputFile)
    if($Job.ContainsKey('password')){$arguments.Add('--password='+$Job.password)}
    if($Job.ContainsKey('encrypt')){
        $arguments.Add('--encrypt');$arguments.Add('--user-password='+$Job.encrypt.userPassword);$arguments.Add('--owner-password='+$Job.encrypt.ownerPassword);$arguments.Add('--bits=256');$arguments.Add('--')
    }
    foreach($key in @('check','showNpages','decrypt')){if($Job.ContainsKey($key)){$arguments.Add(@{check='--check';showNpages='--show-npages';decrypt='--decrypt'}[$key])}}
    if($Job.ContainsKey('outputFile')){$arguments.Add([string]$Job.outputFile)}
    foreach($argument in $arguments){if($argument -match '[\r\n\x00]'){throw 'Newlines and NUL are not accepted in passwords or private arguments.'}}
    $privateInput=($arguments -join "`n")+"`n"
    try { $r=Invoke-Native $Executable @('@-') 0 $privateInput }
    finally {$privateInput=$null;$arguments.Clear()}
    if($r.Code -ne 0){throw 'qpdf refused the operation: invalid password, damaged PDF, or unsupported options. No output published.'}
    $r
}
