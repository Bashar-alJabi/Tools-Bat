param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Image Info' $PSScriptRoot $Mode 'magick' 'Read dimensions, format, frame count, colorspace and metadata into a text report.'
    $null=Read-LocalChoice $Mode @('Create detailed image reports')
    $files=@(Get-SafeFiles $script:InputDir @('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.gif','.avif'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.info.txt'} {
        param($source,$result,$file)
        $report=Invoke-Checked $script:Engine @('identify','-verbose',[IO.Path]::GetFileName($source))
        [IO.File]::WriteAllText($result,('File: '+$file.Name+"`r`n"+$report),(New-Object Text.UTF8Encoding($true)))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
