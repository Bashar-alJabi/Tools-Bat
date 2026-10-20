param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Video Metadata Report' $PSScriptRoot $Mode 'ffprobe' 'Video Metadata Report: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$null=Read-LocalChoice $Mode @('Batch video/stream rows and codec, dimensions, FPS and duration statistics')
$files=@(Get-SafeFiles $script:InputDir $videoExt)
function Field($Object,[string]$Key){if($Object -and $Object.PSObject.Properties[$Key]){$Object.$Key}else{''}}
function Write-VideoReport([string]$result,[IO.FileInfo[]]$all) {
 if($all.Count -gt 1000){throw 'At most 1000 files per report.'}
 $rows=@();$tracks=@()
 foreach($f in $all){
  $p=(Invoke-Checked $script:Engine @('-v','error','-show_format','-show_streams','-of','json',$f.FullName))|ConvertFrom-Json
  $vs=@($p.streams|Where-Object codec_type -eq 'video');if(-not $vs.Count){throw ('No video stream: '+$f.Name)};$v=$vs[0]
  $duration=Field $p.format 'duration';$seconds=if($duration){[double]::Parse([string]$duration,[Globalization.CultureInfo]::InvariantCulture)}else{0}
  $rate=[string](Field $v 'avg_frame_rate');$fps=0.0
  if($rate -match '^(\d+)/([1-9]\d*)$'){$fps=[Math]::Round([double]$Matches[1]/[double]$Matches[2],6)}
  $rows+=[pscustomobject]@{Name=$f.Name;Bytes=$f.Length;DurationSeconds=$seconds;VideoCodec=$v.codec_name;Width=$v.width;Height=$v.height;Dimensions=([string]$v.width+'x'+$v.height);AverageFPS=$fps;Bitrate=Field $p.format 'bit_rate';AudioTracks=@($p.streams|Where-Object codec_type -eq 'audio').Count;SubtitleTracks=@($p.streams|Where-Object codec_type -eq 'subtitle').Count}
  foreach($s in $p.streams){$tags=Field $s 'tags';$tracks+=[pscustomobject]@{File=$f.Name;Index=$s.index;Type=$s.codec_type;Codec=Field $s 'codec_name';Language=Field $tags 'language';Title=Field $tags 'title'}}
 }
 $rows|Export-Csv -LiteralPath (Join-Path $result 'videos.csv') -NoTypeInformation -Encoding UTF8
 $tracks|Export-Csv -LiteralPath (Join-Path $result 'tracks.csv') -NoTypeInformation -Encoding UTF8
 [pscustomobject]@{Count=$rows.Count;TotalBytes=[long]($rows|Measure-Object Bytes -Sum).Sum;TotalDurationSeconds=($rows|Measure-Object DurationSeconds -Sum).Sum;Codecs=@($rows|Group-Object VideoCodec|Select-Object Name,Count);Dimensions=@($rows|Group-Object Dimensions|Select-Object Name,Count);AverageFPSGroups=@($rows|Group-Object AverageFPS|Select-Object Name,Count);Longest=@($rows|Sort-Object DurationSeconds -Descending|Select-Object -First 10)}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $result 'summary.json') -Encoding UTF8
}
if(-not $files.Count){Write-Host '[INFO] No supported input files.';exit 0}
$destination=Join-Path $script:OutputDir 'video-report'
if(Test-Path -LiteralPath $destination){Write-Host '[SKIPPED] video-report exists.';exit 0}
if($destination.Length -gt 200){throw 'Choose a shorter project path.'}
Test-FreeSpace $script:OutputDir 16MB
$work=New-WorkDirectory $script:OutputDir
try{$result=Join-Path $work 'result';Ensure-Directory $result;Write-VideoReport $result $files;[IO.Directory]::Move($result,$destination)}finally{Remove-WorkDirectory $work $script:OutputDir}
Write-Host '[SUCCESS] video-report';Write-Host 'Total: 1 Successful: 1 Failed: 0 Skipped: 0'
exit 0
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
