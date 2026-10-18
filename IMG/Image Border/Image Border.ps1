param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Image Border' $PSScriptRoot $Mode 'magick' 'Add a solid border around the full image; output is PNG.'
    $choice=Read-LocalChoice $Mode @('White 20-pixel border','Black 20-pixel border','Custom width and white/black')
    $width='20';$color=if($choice -eq 2){'black'}else{'white'}
    if($choice -eq 3){$width=Read-LocalNumber 'Border width in pixels (1-1000)' 1 1000;if($width -notmatch '^\d+$'){throw 'Width must be an integer.'};$c=Read-LocalChoice 'Interactive' @('White','Black');$color=@('white','black')[$c-1]}
    $files=@(Get-SafeFiles $script:InputDir @('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.gif','.avif'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.border.png'} {
        param($source,$result)
        $frames=Invoke-Checked $script:Engine @('identify','-format','%n\n',[IO.Path]::GetFileName($source))
        if([int](($frames.Trim()-split '\s+')[0]) -ne 1){throw 'Single-frame images only.'}
        [void](Invoke-Checked $script:Engine @([IO.Path]::GetFileName($source),'-auto-orient','-bordercolor',$color,'-border',($width+'x'+$width),[IO.Path]::GetFileName($result)))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
