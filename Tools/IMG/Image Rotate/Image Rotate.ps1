param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Image Rotate' $PSScriptRoot $Mode 'magick' 'Rotate images into a new PNG; originals are preserved.'
    $choice=Read-LocalChoice $Mode @('90 degrees clockwise','90 degrees counterclockwise','180 degrees')
    $angle=@('90','-90','180')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.gif','.avif'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.rotated.png'} {
        param($source,$result)
        $frames=Invoke-Checked $script:Engine @('identify','-format','%n\n',[IO.Path]::GetFileName($source))
        if([int](($frames.Trim()-split '\s+')[0]) -ne 1){throw 'Single-frame images only; animation is not flattened.'}
        [void](Invoke-Checked $script:Engine @([IO.Path]::GetFileName($source),'-auto-orient','-rotate',$angle,[IO.Path]::GetFileName($result)))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
