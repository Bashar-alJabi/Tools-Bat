param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
    Show-LocalTool 'Video Trim' $PSScriptRoot $Mode 'ffmpeg' 'Cut a precise segment by re-encoding H.264/AAC to MP4.'
    $choice=Read-LocalChoice $Mode @('First 10 seconds','Custom start and duration in seconds')
    $start='0';$duration='10'
    if($choice -eq 2){$start=Read-LocalNumber 'Start seconds (0-86400)' 0 86400;$duration=Read-LocalNumber 'Duration seconds (0.001-86400)' 0.001 86400}
    $files=@(Get-SafeFiles $script:InputDir @('.mp4','.mkv','.mov','.avi','.m4v','.webm'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.trim.mp4'} {
        param($source,$result)
        Invoke-LocalFF @('-i',$source,'-ss',$start,'-t',$duration,'-map','0:v:0','-map','0:a:0?','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-movflags','+faststart',$result)
        $media=(Invoke-Checked $probe @('-v','error','-show_format','-show_streams','-of','json',$result))|ConvertFrom-Json
        if(-not @($media.streams|Where-Object codec_type -eq 'video').Count -or [double]$media.format.duration -le 0){throw 'The selected range contains no video frames.'}
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
