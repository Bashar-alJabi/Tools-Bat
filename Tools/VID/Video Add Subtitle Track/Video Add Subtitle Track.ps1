param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Add Subtitle Track' $PSScriptRoot $Mode 'ffmpeg' 'Video Add Subtitle Track: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$null=Read-LocalChoice $Mode @('Add matching SRT/ASS as a selectable track in MKV')
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.with-subtitle.mkv'} {
 param($source,$result,$file)
 $subs=@(Get-SafeFiles (Join-Path $script:InputDir 'Subtitles') @('.srt','.ass')|Where-Object BaseName -eq $file.BaseName)
 if($subs.Count -ne 1){throw 'Exactly one matching SRT/ASS is required in Input\Subtitles.'}
 $text=[IO.File]::ReadAllText($subs[0].FullName,(New-Object Text.UTF8Encoding($false,$true)))
 if($subs[0].Extension -ieq '.srt' -and $text -notmatch '\d{2}:\d{2}:\d{2},\d{3}\s+-->'){throw 'Invalid UTF-8 SRT timing.'}
 if($subs[0].Extension -ieq '.ass' -and $text -notmatch '\[Events\]'){throw 'Invalid ASS Events section.'}
 $alias='subtitle'+$subs[0].Extension.ToLowerInvariant();[IO.File]::Copy($subs[0].FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
 Invoke-LocalFF @('-i',$source,'-i',$alias,'-map','0:v','-map','0:a?','-map','0:s?','-map','1:0','-c','copy','-map_metadata','0',$result)
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
