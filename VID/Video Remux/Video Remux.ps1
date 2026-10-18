param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Video Remux' $PSScriptRoot $Mode 'ffmpeg' 'Copy video/audio/subtitle streams into MKV or MP4 without re-encoding.'
    $choice=Read-LocalChoice $Mode @('MKV container','MP4 container (compatible codecs only)')
    $extension=@('.mkv','.mp4')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.mp4','.mkv','.mov','.avi','.m4v','.webm'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.remux'+$extension} {
        param($source,$result)
        Invoke-LocalFF @('-i',$source,'-map','0:v','-map','0:a?','-map','0:s?','-c','copy','-map_metadata','0',$result)
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
