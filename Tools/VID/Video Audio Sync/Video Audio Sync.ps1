param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Audio Sync' $PSScriptRoot $Mode 'ffmpeg' 'Video Audio Sync: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('Delay audio by +0.250 seconds','Custom signed offset (-60 to 60 seconds)')
$offset='0.250'
if($choice -eq 2){$offset=Read-Host 'Signed seconds, e.g. +0.250 or -0.500';if($offset -notmatch '^[+-]?\d{1,2}(\.\d{1,3})?$'){throw 'Invalid signed offset.'}}
$value=[double]::Parse($offset,[Globalization.CultureInfo]::InvariantCulture);if([Math]::Abs($value) -gt 60){throw 'Offset exceeds 60 seconds.'}
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.synced.mkv'} {
 param($source,$result)
 $p=Probe $source;if(-not @($p.streams|Where-Object codec_type -eq 'audio').Count){throw 'A source audio track is required.'}
 $duration=[double]::Parse([string]$p.format.duration,[Globalization.CultureInfo]::InvariantCulture)
 if($duration -le 0 -or -$value -ge $duration){throw 'Offset removes the entire audio range.'}
 $filter=if($value -ge 0){'adelay='+[Math]::Round($value*1000)+':all=1,apad'}else{'atrim=start='+(-$value).ToString('0.000',[Globalization.CultureInfo]::InvariantCulture)+',asetpts=PTS-STARTPTS,apad'}
 Invoke-LocalFF @('-i',$source,'-map','0:v:0','-map','0:a:0','-c:v','copy','-af',$filter,'-c:a','aac','-t',($duration.ToString('0.000',[Globalization.CultureInfo]::InvariantCulture)),$result)
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
