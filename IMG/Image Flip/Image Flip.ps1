param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Image Flip' $PSScriptRoot $Mode 'magick' 'Mirror an image horizontally or vertically; output is PNG.'
    $choice=Read-LocalChoice $Mode @('Horizontal mirror','Vertical mirror')
    $flip=@('-flop','-flip')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.gif','.avif'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.flipped.png'} {
        param($source,$result)
        $frames=Invoke-Checked $script:Engine @('identify','-format','%n\n',[IO.Path]::GetFileName($source))
        if([int](($frames.Trim()-split '\s+')[0]) -ne 1){throw 'Single-frame images only.'}
        [void](Invoke-Checked $script:Engine @([IO.Path]::GetFileName($source),'-auto-orient',$flip,[IO.Path]::GetFileName($result)))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
