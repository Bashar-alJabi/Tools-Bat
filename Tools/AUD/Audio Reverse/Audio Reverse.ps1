param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Audio Reverse' $PSScriptRoot $Mode 'ffmpeg' 'Audio Reverse: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$null=Read-LocalChoice $Mode @('Reverse the first audio stream into a new WAV')
$files=@(Get-SafeFiles $script:InputDir $audioExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.reversed.wav'} {
 param($source,$result)
 $p=Probe $source;$streams=@($p.streams|Where-Object codec_type -eq 'audio');if(-not $streams.Count){throw 'No audio stream.'}
 $duration=[double]::Parse([string]$p.format.duration,[Globalization.CultureInfo]::InvariantCulture);$a=$streams[0]
 if($duration -le 0 -or $duration -gt 600 -or $duration*[double]$a.sample_rate*[int]$a.channels*4 -gt 256MB){throw 'Reverse is buffered; limit 600 seconds and estimated 256MB decoded samples.'}
 Invoke-LocalFF @('-i',$source,'-map','0:a:0','-vn','-af','areverse','-c:a','pcm_s16le',$result)
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
