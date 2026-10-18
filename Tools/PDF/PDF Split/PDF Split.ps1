param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'PDF Split' $PSScriptRoot $Mode 'ghostscript' 'Create one PDF per page, up to the first 1000 pages, in a new folder.'
    $null=Read-LocalChoice $Mode @('Split pages 1-1000 into separate PDFs')
    $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.pages'} {
        param($source,$result)
        [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dFirstPage=1','-dLastPage=1000',('-sOutputFile='+'result\page-%04d.pdf'),[IO.Path]::GetFileName($source)))
    } -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
