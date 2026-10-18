param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Audio Concatenate' $PSScriptRoot $Mode 'ffmpeg' 'Join clips in filename order into stereo 48 kHz WAV; use 001, 002 prefixes.'
    $null=Read-LocalChoice $Mode @('Join all audio files in filename order')
    $files=@(Get-SafeFiles $script:InputDir @('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma'))
    Invoke-LocalBatch $files { 'joined.wav' } {
        param($source,$result,$file,$all)
        if($all.Count -gt 100){throw 'At most 100 clips per operation.'}
        $work=Split-Path $result;$list=@();$i=0
        foreach($clip in $all){$i++;$name=('clip-{0:D4}.wav' -f $i);Invoke-LocalFF @('-i',$clip.FullName,'-map','0:a:0','-vn','-ar','48000','-ac','2','-c:a','pcm_s16le',(Join-Path $work $name));$list+="file '$name'"}
        [IO.File]::WriteAllLines((Join-Path $work 'clips.txt'),$list,(New-Object Text.ASCIIEncoding))
        Invoke-LocalFF @('-f','concat','-safe','1','-i',(Join-Path $work 'clips.txt'),'-c:a','copy',$result)
    } -Aggregate
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
