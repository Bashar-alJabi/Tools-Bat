param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Screenshot at Time' $PSScriptRoot $Mode 'ffmpeg' 'Video Screenshot at Time: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('Screenshot at 1 second','Custom time in seconds')
$time='1';if($choice -eq 2){$time=Read-LocalNumber 'Time in seconds (0-86400)' 0 86400}
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.at-time.png'} {
 param($source,$result)
 $p=Probe $source;$duration=[double]::Parse([string]$p.format.duration,[Globalization.CultureInfo]::InvariantCulture)
 if([double]$time -ge $duration){throw 'Requested time must be before the end.'}
 Invoke-LocalFF @('-i',$source,'-ss',$time,'-map','0:v:0','-frames:v','1','-an','-update','1',$result)
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
