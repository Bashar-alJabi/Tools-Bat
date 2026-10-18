param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Image Grayscale' $PSScriptRoot $Mode 'magick' 'Create grayscale PNG copies while retaining transparency.'
    $null=Read-LocalChoice $Mode @('Convert to grayscale')
    $files=@(Get-SafeFiles $script:InputDir @('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.gif','.avif'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.gray.png'} {
        param($source,$result)
        $frames=Invoke-Checked $script:Engine @('identify','-format','%n\n',[IO.Path]::GetFileName($source))
        if([int](($frames.Trim()-split '\s+')[0]) -ne 1){throw 'Single-frame images only.'}
        [void](Invoke-Checked $script:Engine @([IO.Path]::GetFileName($source),'-auto-orient','-colorspace','Gray',[IO.Path]::GetFileName($result)))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
