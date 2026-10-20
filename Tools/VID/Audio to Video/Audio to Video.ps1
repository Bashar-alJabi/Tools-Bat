param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Audio to Video' $PSScriptRoot $Mode 'ffmpeg' 'Audio to Video: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$choice=Read-LocalChoice $Mode @('Black 1280x720 background, 25fps','One still image from Input\Picture')
$files=@(Get-SafeFiles $script:InputDir $audioExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.video.mp4'} {
 param($source,$result)
 $p=Probe $source;$duration=[double]::Parse([string]$p.format.duration,[Globalization.CultureInfo]::InvariantCulture)
 if($duration -le 0){throw 'No finite audio duration.'}
 if($choice -eq 2){
  $pictures=@(Get-SafeFiles (Join-Path $script:InputDir 'Picture') @('.png','.jpg','.jpeg','.bmp','.webp'));if($pictures.Count -ne 1){throw 'Exactly one image is required in Input\Picture.'}
  $alias='picture'+$pictures[0].Extension;[IO.File]::Copy($pictures[0].FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
  $frames=(Invoke-Checked $probe @('-v','error','-select_streams','v:0','-count_frames','-show_entries','stream=nb_read_frames','-of','default=nw=1:nk=1',$alias)).Trim()
  if($frames -ne '1'){throw 'Picture must be a single-frame still image.'};$args=@('-loop','1','-framerate','25','-i',$alias)
 }else{$args=@('-f','lavfi','-i','color=c=black:s=1280x720:r=25')}
 Invoke-LocalFF ($args+@('-i',$source,'-map','0:v:0','-map','1:a:0','-vf','scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1','-c:v','libx264','-preset','fast','-tune','stillimage','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-t',($duration.ToString('0.000',[Globalization.CultureInfo]::InvariantCulture)),'-shortest','-movflags','+faststart',$result))
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
