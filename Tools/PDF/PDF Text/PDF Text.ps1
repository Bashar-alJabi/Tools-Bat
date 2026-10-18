param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'PDF Text' $PSScriptRoot $Mode 'ghostscript' 'Extract the text layer of PDF to UTF-8 text. Scanned pages need separate OCR.'
    $null=Read-LocalChoice $Mode @('Extract text layer')
    $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.txt'} {
        param($source,$result)
        [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=txtwrite','-dTextFormat=3',('-sOutputFile='+[IO.Path]::GetFileName($result)),[IO.Path]::GetFileName($source)))
        if(-not (Test-Path -LiteralPath $result) -or -not [IO.File]::ReadAllText($result).Trim()){throw 'No text layer found; this tool does not perform OCR.'}
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
