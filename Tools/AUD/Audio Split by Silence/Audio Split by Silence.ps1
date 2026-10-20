param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Audio Split by Silence' $PSScriptRoot $Mode 'ffmpeg' 'Audio Split by Silence: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$choice=Read-LocalChoice $Mode @('Split gaps at -45dB, 0.7s silence, 0.3s minimum clip','Custom threshold, silence duration and minimum clip')
$threshold='-45';$silence='0.7';$minimum=0.3
if($choice -eq 2){$threshold='-'+(Read-LocalNumber 'Threshold magnitude below 0dB (20-80)' 20 80);$silence=Read-LocalNumber 'Silence seconds (0.1-10)' 0.1 10;$minimum=[double](Read-LocalNumber 'Minimum clip seconds (0.1-60)' 0.1 60)}
$files=@(Get-SafeFiles $script:InputDir $audioExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.segments'} {
 param($source,$result)
 $p=Probe $source;$duration=[double]::Parse([string]$p.format.duration,[Globalization.CultureInfo]::InvariantCulture)
 $scan=Invoke-Native $script:Engine @('-hide_banner','-loglevel','info','-nostdin','-i',$source,'-map','0:a:0','-af',('silencedetect=noise='+$threshold+'dB:d='+$silence),'-f','null','-')
 if($scan.Code -ne 0){throw $scan.Err}
 $gaps=@();$open=$null
 foreach($m in [regex]::Matches($scan.Err,'silence_(start|end): ([\d.]+)')){
  $value=[double]::Parse($m.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)
  if($m.Groups[1].Value -eq 'start'){$open=$value}elseif($null -ne $open){$gaps+=[pscustomobject]@{Start=$open;End=$value};$open=$null}
 }
 if($null -ne $open){$gaps+=[pscustomobject]@{Start=$open;End=$duration}}
 $start=0.0;$end=$duration
 if($gaps.Count -and $gaps[0].Start -le 0.001){$start=$gaps[0].End}
 if($gaps.Count -and $gaps[-1].End -ge ($duration-0.01)){$end=$gaps[-1].Start}
 if($end -le $start){throw 'Entire recording is silent at the selected threshold.'}
 $points=@($start)
 foreach($gap in $gaps){$cut=($gap.Start+$gap.End)/2;if(($cut-$points[-1]) -ge $minimum -and ($end-$cut) -ge $minimum){$points+=$cut}}
 $points+=$end;if($points.Count -gt 201){throw 'More than 200 clips; increase silence duration or the minimum clip length.'}
 $rows=@(for($i=0;$i -lt ($points.Count-1);$i++){
  $name='part-'+('{0:D4}' -f ($i+1))+'.wav';$length=$points[$i+1]-$points[$i]
  Invoke-LocalFF @('-i',$source,'-ss',($points[$i].ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)),'-t',($length.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)),'-map','0:a:0','-vn','-c:a','pcm_s16le',(Join-Path $result $name))
  [pscustomobject]@{File=$name;SourceStart=$points[$i];SourceEnd=$points[$i+1];Duration=$length}
 })
 $rows|Export-Csv -LiteralPath (Join-Path $result 'segments.csv') -NoTypeInformation -Encoding UTF8
} -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
