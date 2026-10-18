param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Video Rotate' $PSScriptRoot $Mode 'ffmpeg' 'Rotate video pixels and re-encode MP4 with optional audio.'
    $choice=Read-LocalChoice $Mode @('90 degrees clockwise','90 degrees counterclockwise','180 degrees')
    $filter=@('transpose=clock','transpose=cclock','hflip,vflip')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.mp4','.mkv','.mov','.avi','.m4v','.webm'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.rotated.mp4'} {
        param($source,$result)
        Invoke-LocalFF @('-i',$source,'-map','0:v:0','-map','0:a:0?','-vf',$filter,'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-metadata:s:v:0','rotate=0','-movflags','+faststart',$result)
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
