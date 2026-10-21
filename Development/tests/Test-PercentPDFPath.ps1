param([Parameter(Mandatory=$true)][string]$Project)
$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$Project=[IO.Path]::GetFullPath($Project)
if($Project -notmatch '%'){throw 'Supply the extracted project in a path containing percent.'}
. (Join-Path $Project 'System\Shared\Core.ps1')
$beforePath=$env:PATH;$beforeLocal=$env:TB_LOCAL_ONLY
$results=New-Object 'Collections.Generic.List[object]'
try{
    $env:PATH=$env:SystemRoot+'\System32;'+$env:SystemRoot;$env:TB_LOCAL_ONLY='1'
    $script:NativeWorkingDirectory=New-WorkDirectory $Project
    $gs=Get-Dependency ghostscript -LocalOnly;$im=Get-Dependency magick -LocalOnly
    if(-not $gs.Local -or -not $im.Local){throw 'Expected extracted local programs.'}
    [void](Invoke-Checked $gs.Path @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=source.pdf','-c','/Helvetica findfont 24 scalefont setfont 72 720 moveto (PERCENT ROOT TEST) show showpage'))
    $source=Join-Path $script:NativeWorkingDirectory 'source.pdf';$before=(Get-FileHash -LiteralPath $source).Hash
    [void](Invoke-Checked $im.Path @('-density','72','source.pdf[0]','result.png'))
    $dimensions=Invoke-Checked $im.Path @('identify','-format','%w %h','result.png')
    if($dimensions.Trim() -ne '612 792'){throw ('Wrong PDF render geometry: '+$dimensions)}
    [void](Invoke-Checked $gs.Path @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=txtwrite','-sOutputFile=text.txt','source.pdf'))
    if(-not [IO.File]::ReadAllText((Join-Path $script:NativeWorkingDirectory 'text.txt')).Contains('PERCENT ROOT TEST')){throw 'PDF text content lost.'}
    if((Get-FileHash -LiteralPath $source).Hash -cne $before){throw 'Source PDF changed.'}
    $results.Add([pscustomobject]@{Test='Percent project path PDF render';Passed=$true;Detail='Extracted Core.ps1 and local GS/IM rendered a real PDF at72dpi to612x792; known text and source hash retained. Process PATH restricted to Windows; owned native scratch inside moved project.'})
    Write-Host 'PASS Percent project path PDF render: 612x792, known text and original SHA-256 preserved.'
}catch{$results.Add([pscustomobject]@{Test='Percent project path PDF render';Passed=$false;Detail=$_.Exception.Message.Replace($repository,'<PROJECT_ROOT>')});Write-Host ('FAIL '+$_.Exception.Message)}
finally{
    $env:PATH=$beforePath;$env:TB_LOCAL_ONLY=$beforeLocal
    [pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Project=$Project.Replace($repository,'<PROJECT_ROOT>');Results=$results.ToArray()}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'percent-pdf-path-results.json') -Encoding UTF8
}
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
