param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
    Show-LocalTool 'Audio Trim' $PSScriptRoot $Mode 'ffmpeg' 'Cut an audio segment into uncompressed 16-bit WAV.'
    $choice=Read-LocalChoice $Mode @('First 10 seconds','Custom start and duration in seconds')
    $start='0';$duration='10'
    if($choice -eq 2){$start=Read-LocalNumber 'Start seconds (0-86400)' 0 86400;$duration=Read-LocalNumber 'Duration seconds (0.001-86400)' 0.001 86400}
    $files=@(Get-SafeFiles $script:InputDir @('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.trim.wav'} {
        param($source,$result)
        Invoke-LocalFF @('-i',$source,'-ss',$start,'-t',$duration,'-map','0:a:0','-vn','-c:a','pcm_s16le',$result)
        $durationText=(Invoke-Checked $probe @('-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',$result)).Trim()
        if($durationText -notmatch '^\d+(\.\d+)?$' -or [double]::Parse($durationText,[Globalization.CultureInfo]::InvariantCulture) -le 0){throw 'The selected range contains no audio samples.'}
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
