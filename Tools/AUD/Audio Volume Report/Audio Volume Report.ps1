param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Audio Volume Report' $PSScriptRoot $Mode 'ffmpeg' 'Audio Volume Report: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$null=Read-LocalChoice $Mode @('Measure mean/peak dBFS, integrated LUFS, true peak and LRA; no file changes')
$files=@(Get-SafeFiles $script:InputDir $audioExt)
Invoke-LocalBatch $files {'audio-volume.csv'} {
 param($source,$result,$file,$all)
 $rows=@(foreach($f in $all){
  $p=Probe $f.FullName
  $volume=Invoke-Native $script:Engine @('-hide_banner','-nostdin','-i',$f.FullName,'-map','0:a:0','-vn','-af','volumedetect','-f','null','-')
  if($volume.Code -ne 0 -or $volume.Err -notmatch 'mean_volume: (\S+) dB'){throw 'Mean volume analysis failed.'};$mean=$Matches[1]
  if($volume.Err -notmatch 'max_volume: (\S+) dB'){throw 'Peak analysis failed.'};$peak=$Matches[1]
  $loud=Invoke-Native $script:Engine @('-hide_banner','-nostdin','-i',$f.FullName,'-map','0:a:0','-vn','-af','loudnorm=print_format=json','-f','null','-')
  $match=[regex]::Match($loud.Err,'(?s)\{\s*"input_i".*?\}')
  if($loud.Code -ne 0 -or -not $match.Success){throw 'Loudness analysis failed.'};$j=$match.Value|ConvertFrom-Json
  [pscustomobject]@{File=$f.Name;DurationSeconds=$p.format.duration;MeanDBFS=$mean;PeakDBFS=$peak;IntegratedLUFS=$j.input_i;TruePeakDBTP=$j.input_tp;LRA=$j.input_lra}
 })
 $rows|Export-Csv -LiteralPath $result -NoTypeInformation -Encoding UTF8
} -Aggregate
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
