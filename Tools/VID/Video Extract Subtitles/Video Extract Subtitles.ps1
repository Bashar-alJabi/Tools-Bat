param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Extract Subtitles' $PSScriptRoot $Mode 'ffmpeg' 'Video Extract Subtitles: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$null=Read-LocalChoice $Mode @('Extract all embedded subtitle streams; no OCR')
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.subtitles'} {
 param($source,$result)
 $p=Probe $source;$tracks=@($p.streams|Where-Object codec_type -eq 'subtitle')
 if(-not $tracks.Count){throw 'No embedded subtitle streams in this video.'}
 $rows=@(foreach($track in $tracks){
  $codec=$track.codec_name;$ext='.srt';$encoder='srt';$kind='Text'
  if($codec -eq 'ass'){$ext='.ass';$encoder='copy'}
  elseif($codec -notin @('subrip','mov_text','webvtt','text')){$kind='ImageOrBinary';$encoder='copy';$ext=if($codec -eq 'hdmv_pgs_subtitle'){'.sup'}else{'.mks'}}
  $name='track-'+$track.index+$ext
  Invoke-LocalFF @('-i',$source,'-map',('0:'+$track.index),'-c:s',$encoder,(Join-Path $result $name))
  [pscustomobject]@{StreamIndex=$track.index;Codec=$codec;Kind=$kind;File=$name;OCR=$false}
 })
 $rows|Export-Csv -LiteralPath (Join-Path $result 'tracks.csv') -NoTypeInformation -Encoding UTF8
} -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
