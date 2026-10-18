param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Audio Normalize' $PSScriptRoot $Mode 'ffmpeg' 'Normalize standalone audio loudness into 48 kHz 16-bit WAV.'
    $choice=Read-LocalChoice $Mode @('-16 LUFS for spoken audio','-23 LUFS broadcast target')
    $target=@('-16','-23')[$choice-1]
    $files=@(Get-SafeFiles $script:InputDir @('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.normalized.wav'} {
        param($source,$result)
        Invoke-LocalFF @('-i',$source,'-map','0:a:0','-vn','-af',('loudnorm=I='+$target+':TP=-1.5:LRA=11'),'-ar','48000','-c:a','pcm_s16le',$result)
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
