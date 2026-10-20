param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Watermark' $PSScriptRoot $Mode 'ffmpeg' 'Video Watermark: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('Bottom right, width20%, opacity60%','Top left, width20%, opacity60%','Custom position, size and opacity')
$position=if($choice -eq 2){1}else{4};$size='20';$opacity='60'
if($choice -eq 3){$position=Read-LocalChoice 'Interactive' @('Top left','Top right','Bottom left','Bottom right','Center');$size=Read-LocalNumber 'Width percent (1-80)' 1 80;$opacity=Read-LocalNumber 'Opacity percent (1-100)' 1 100}
$logos=@(Get-SafeFiles (Join-Path $PSScriptRoot 'Watermark') $imageExt)
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.watermarked.mp4'} {
 param($source,$result)
 if($logos.Count -ne 1){throw 'Exactly one still image is required in Watermark.'}
 $p=Probe $source;$v=@($p.streams|Where-Object codec_type -eq 'video');if(-not $v.Count){throw 'No video stream.'}
 $logo='logo'+$logos[0].Extension;[IO.File]::Copy($logos[0].FullName,(Join-Path $script:NativeWorkingDirectory $logo),$false)
 $w=[Math]::Max(2,[int]($v[0].width*[double]$size/100));$alpha=([double]$opacity/100).ToString('0.000',[Globalization.CultureInfo]::InvariantCulture)
 $xy=@('0:0','W-w:0','0:H-h','W-w:H-h','(W-w)/2:(H-h)/2')[$position-1]
 $filter=('[1:v]scale={0}:-1,format=rgba,colorchannelmixer=aa={1}[logo];[0:v][logo]overlay={2}:shortest=1[v]' -f $w,$alpha,$xy)
 Invoke-LocalFF @('-i',$source,'-loop','1','-i',$logo,'-filter_complex',$filter,'-map','[v]','-map','0:a:0?','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-shortest','-movflags','+faststart',$result)
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
