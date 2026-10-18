param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'PDF To Images' $PSScriptRoot $Mode 'ghostscript' 'Render the first 100 PDF pages into PNG copies; no OCR.'
    $choice=Read-LocalChoice $Mode @('120 DPI preview','200 DPI detailed')
    $dpi=@('120','200')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.images'} {
        param($source,$result)
        [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=png16m',('-r'+$dpi),'-dFirstPage=1','-dLastPage=100','-dTextAlphaBits=4','-dGraphicsAlphaBits=4',('-sOutputFile='+'result\page-%04d.png'),[IO.Path]::GetFileName($source)))
    } -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
