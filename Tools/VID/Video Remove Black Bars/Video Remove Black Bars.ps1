param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Remove Black Bars' $PSScriptRoot $Mode 'ffmpeg' 'Video Remove Black Bars: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

function Display-Size($Video){
 $rotation=0.0
 if($Video.PSObject.Properties['tags'] -and $Video.tags.PSObject.Properties['rotate']){$rotation=[double]$Video.tags.rotate}
 if($Video.PSObject.Properties['side_data_list']){foreach($s in $Video.side_data_list){if($s.PSObject.Properties['rotation']){$rotation=[double]$s.rotation}}}
 if([Math]::Abs($rotation%90) -gt 0.001){throw 'Only right-angle display rotation is supported; normalize a copy first.'}
 if([Math]::Abs($rotation%180) -gt 0.001){return @([int]$Video.height,[int]$Video.width)}
 return @([int]$Video.width,[int]$Video.height)
}
$choice=Read-LocalChoice $Mode @('Detection report and preview only','Preview, then APPLY confirmation for each crop')
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.crop-preview'} {
 param($source,$result)
 $p=Probe $source;$video=@($p.streams|Where-Object codec_type -eq 'video');if(-not $video.Count){throw 'No video stream.'}
 $display=Display-Size $video[0];$width=$display[0];$height=$display[1]
 $scan=Invoke-Native $script:Engine @('-hide_banner','-loglevel','info','-nostdin','-i',$source,'-t','30','-map','0:v:0','-vf','cropdetect=limit=24:round=2:reset=0','-an','-f','null','-')
 if($scan.Code -ne 0){throw $scan.Err}
 $rects=@([regex]::Matches($scan.Err,'crop=(\d+):(\d+):(\d+):(\d+)')|ForEach-Object {[pscustomobject]@{W=[int]$_.Groups[1].Value;H=[int]$_.Groups[2].Value;X=[int]$_.Groups[3].Value;Y=[int]$_.Groups[4].Value}}|Where-Object {$_.W -gt 0 -and $_.H -gt 0 -and ($_.X+$_.W) -le $width -and ($_.Y+$_.H) -le $height})
 $x=0;$y=0;$w=$width;$h=$height
 if($rects.Count){$x=[int]($rects|Measure-Object X -Minimum).Minimum;$y=[int]($rects|Measure-Object Y -Minimum).Minimum;$right=($rects|ForEach-Object {$_.X+$_.W}|Measure-Object -Maximum).Maximum;$bottom=($rects|ForEach-Object {$_.Y+$_.H}|Measure-Object -Maximum).Maximum;$w=[int]($right-$x);$h=[int]($bottom-$y)}
 $filter=('crop={0}:{1}:{2}:{3}' -f $w,$h,$x,$y);Write-Host ('[PREVIEW] '+$filter+' from '+$width+'x'+$height)
 [pscustomobject]@{OriginalWidth=$width;OriginalHeight=$height;CropWidth=$w;CropHeight=$h;X=$x;Y=$y;SampleSeconds=30;Candidates=$rects.Count}|Export-Csv -LiteralPath (Join-Path $result 'crop.csv') -NoTypeInformation -Encoding UTF8
 Invoke-LocalFF @('-i',$source,'-vf',$filter,'-frames:v','1','-an','-update','1',(Join-Path $result 'preview.png'))
 if($choice -eq 2){
  $answer=Read-Host 'Review the dimensions above; type APPLY to crop this copy'
  if($answer -ceq 'APPLY'){Invoke-LocalFF @('-i',$source,'-vf',$filter,'-map','0:v:0','-map','0:a:0?','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac',(Join-Path $result 'cropped.mp4'))}
  else{Write-Host '[INFO] Crop declined; preview/report only.'}
 }
} -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
