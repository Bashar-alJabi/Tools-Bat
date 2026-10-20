param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Audio Remove Silence' $PSScriptRoot $Mode 'ffmpeg' 'Audio Remove Silence: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$choice=Read-LocalChoice $Mode @('Trim leading/trailing silence only (-50dB, 1s)','Also remove internal gaps (-50dB, 1s)','Custom internal-gap threshold and duration')
$threshold='-50';$minimum='1'
if($choice -eq 3){$threshold='-'+(Read-LocalNumber 'Threshold magnitude below 0dB (20-80)' 20 80);$minimum=Read-LocalNumber 'Minimum silence seconds (0.1-10)' 0.1 10}
$files=@(Get-SafeFiles $script:InputDir $audioExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.no-silence.wav'} {
 param($source,$result)
 $p=Probe $source;$duration=[double]::Parse([string]$p.format.duration,[Globalization.CultureInfo]::InvariantCulture)
 $scan=Invoke-Native $script:Engine @('-hide_banner','-loglevel','info','-nostdin','-i',$source,'-map','0:a:0','-af',('silencedetect=noise='+$threshold+'dB:d='+$minimum),'-f','null','-')
 if($scan.Code -ne 0){throw $scan.Err}
 $start=0.0;$end=$duration;$open=$null;$silences=@()
 foreach($m in [regex]::Matches($scan.Err,'silence_(start|end): ([\d.]+)')){
  $t=[double]::Parse($m.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)
  if($m.Groups[1].Value -eq 'start'){$open=$t}elseif($null -ne $open){$silences+=[pscustomobject]@{Start=$open;End=$t};$open=$null}
 }
 if($null -ne $open){$silences+=[pscustomobject]@{Start=$open;End=$duration}}
 if($silences.Count -and $silences[0].Start -le 0.001){$start=$silences[0].End}
 if($silences.Count -and $silences[-1].End -ge ($duration-0.01)){$end=$silences[-1].Start}
 if($end -le $start){throw 'The recording is entirely silent at this threshold; no empty WAV was published.'}
 Write-Host ('[INFO] Threshold '+$threshold+'dB; silence duration '+$minimum+'s. Quiet speech can be removed; inspect the copy.')
 if($choice -eq 1){
  $filter='atrim=start='+$start.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)+':end='+$end.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)+',asetpts=PTS-STARTPTS'
  Invoke-LocalFF @('-i',$source,'-map','0:a:0','-vn','-af',$filter,'-c:a','pcm_s16le',$result)
 }else{
  # Use the measured intervals for every cut. This avoids disagreement between
  # silencedetect and silenceremove at an exact minimum-duration boundary.
  $cursor=0.0;$keep=@()
  foreach($gap in $silences){
   if($gap.Start -gt 0.001){$stop=[Math]::Min($duration,$gap.Start+0.1);if($stop -gt $cursor){$keep+=[pscustomobject]@{Start=$cursor;End=$stop}}}
   $cursor=if($gap.End -ge ($duration-0.01)){$duration}else{[Math]::Max(0,$gap.End-0.1)}
  }
  if($cursor -lt $duration){$keep+=[pscustomobject]@{Start=$cursor;End=$duration}}
  if(-not $keep.Count -or $keep.Count -gt 200){throw 'No sound remained, or more than 200 retained intervals; adjust the threshold/duration.'}
  $list=@();$i=0
  foreach($part in $keep){$i++;$name='sound'+$i+'.wav';Invoke-LocalFF @('-i',$source,'-ss',($part.Start.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)),'-t',(($part.End-$part.Start).ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)),'-map','0:a:0','-vn','-c:a','pcm_s16le',$name);$list+="file '$name'"}
  [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'sounds.txt'),$list,(New-Object Text.ASCIIEncoding))
  Invoke-LocalFF @('-f','concat','-safe','1','-i','sounds.txt','-c:a','copy',$result)
 }
 $out=Probe $result;if([double]$out.format.duration -le 0){throw 'No audio remained.'}
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
