param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Audio Channels' $PSScriptRoot $Mode 'ffmpeg' 'Downmix to mono or produce two-channel stereo WAV.'
    $choice=Read-LocalChoice $Mode @('Mono (1 channel)','Stereo (2 channels)')
    $channels=@('1','2')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.channels.wav'} {
        param($source,$result)
        Invoke-LocalFF @('-i',$source,'-map','0:a:0','-vn','-ac',$channels,'-c:a','pcm_s16le',$result)
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
