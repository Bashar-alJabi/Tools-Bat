param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
    Show-LocalTool 'Audio Fade' $PSScriptRoot $Mode 'ffmpeg' 'Fade in, fade out, or both; fade duration is at most half the clip.'
    $choice=Read-LocalChoice $Mode @('Fade in and out','Fade in only','Fade out only')
    $files=@(Get-SafeFiles $script:InputDir @('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.fade.wav'} {
        param($source,$result)
        $durationText=(Invoke-Checked $probe @('-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',$source)).Trim()
        $duration=[double]::Parse($durationText,[Globalization.CultureInfo]::InvariantCulture)
        if($duration -le 0){throw 'Audio duration is unavailable.'}
        $fade=[Math]::Min(2,$duration/2);$end=$duration-$fade
        $d=$fade.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture);$s=$end.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)
        $filters=@();if($choice -ne 3){$filters+='afade=t=in:d='+$d};if($choice -ne 2){$filters+='afade=t=out:st='+$s+':d='+$d}
        Invoke-LocalFF @('-i',$source,'-map','0:a:0','-vn','-af',($filters -join ','),'-c:a','pcm_s16le',$result)
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
