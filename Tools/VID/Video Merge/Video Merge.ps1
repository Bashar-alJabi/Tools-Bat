param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Merge' $PSScriptRoot $Mode 'ffmpeg' 'Video Merge: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('Auto: copy compatible streams, otherwise normalize','Normalize to 1280x720 30fps','Compatible stream copy only')
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {'merged.mp4'} {
 param($source,$result,$file,$all)
 if($all.Count -lt 2 -or $all.Count -gt 50){throw 'Use 2-50 clips in filename order.'}
 $media=@();$aliases=@();$fingerprints=@();$i=0
 foreach($f in $all){
  $i++;$alias='clip'+$i+$f.Extension;[IO.File]::Copy($f.FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false);$aliases+=$alias
  $p=Probe $alias;if(@($p.streams|Where-Object codec_type -eq 'video').Count -ne 1){throw 'Exactly one video stream per clip.'};$media+=$p
  $fingerprints+=ConvertTo-Json -InputObject @($p.streams|Select-Object codec_type,codec_name,profile,width,height,pix_fmt,r_frame_rate,time_base,sample_rate,channels,channel_layout,extradata_hash,sample_aspect_ratio,display_aspect_ratio,field_order,color_range,color_space,color_transfer,color_primaries,sample_fmt,side_data_list) -Depth 4 -Compress
 }
 $compatible=@($fingerprints|Select-Object -Unique).Count -eq 1
 foreach($p in $media){if(@($p.streams|Where-Object codec_type -eq 'audio').Count -gt 1 -or @($p.streams|Where-Object {$_.codec_type -notin @('video','audio')}).Count -or $p.streams[0].codec_name -ne 'h264' -or @($p.streams|Where-Object {$_.codec_type -eq 'audio' -and $_.codec_name -ne 'aac'}).Count){$compatible=$false}}
 if($choice -eq 3 -and -not $compatible){throw 'Streams differ; direct concatenation refused. Choose normalization.'}
 $copy=$compatible -and $choice -ne 2;$list=@()
 if($copy){Write-Host '[INFO] Matching stream fingerprints: direct copy without re-encoding.';foreach($alias in $aliases){$list+="file '$alias'"}}
 else{
  Write-Host '[INFO] Re-encoding H.264 1280x720 30fps, AAC stereo 48k. Other tracks omitted.'
  for($i=0;$i -lt $aliases.Count;$i++){
   $duration=[double]::Parse([string]$media[$i].format.duration,[Globalization.CultureInfo]::InvariantCulture);if($duration -le 0){throw 'Invalid duration.'}
   $name='normal'+$i+'.mp4';$args=@('-i',$aliases[$i]);$hasAudio=@($media[$i].streams|Where-Object codec_type -eq 'audio').Count -gt 0
   if(-not $hasAudio){$args+=@('-f','lavfi','-i','anullsrc=r=48000:cl=stereo')}
   $audioMap=if($hasAudio){'0:a:0'}else{'1:a:0'}
   Invoke-LocalFF ($args+@('-map','0:v:0','-map',$audioMap,'-vf','scale=trunc(iw*sar/2)*2:ih,setsar=1,scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,fps=30,setsar=1','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-ar','48000','-ac','2','-t',($duration.ToString('0.000',[Globalization.CultureInfo]::InvariantCulture)),$name));$list+="file '$name'"
  }
 }
 [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'clips.txt'),$list,(New-Object Text.ASCIIEncoding))
 Invoke-LocalFF @('-f','concat','-safe','1','-i','clips.txt','-map','0:v:0','-map','0:a:0?','-c','copy','-movflags','+faststart',$result)
} -Aggregate
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
