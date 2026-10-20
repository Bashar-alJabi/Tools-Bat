param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
if($Mode -ne 'Help'){$probe=Require-Dependency 'ffprobe'}
if($Mode -ne 'Help'){$ff=Require-Dependency 'ffmpeg';$filters=Invoke-Checked $ff @('-hide_banner','-filters');if($filters -notmatch '\bsubtitles\s'){throw 'FFmpeg subtitles/libass filter unavailable; use a compatible build.'}}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-show_data_hash','sha256','-of','json',$Path))|ConvertFrom-Json}
Show-LocalTool 'Video Subtitles Burn' $PSScriptRoot $Mode 'ffmpeg' 'Video Subtitles Burn: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$null=Read-LocalChoice $Mode @('Burn matching UTF-8 SRT/ASS with system fonts')
$files=@(Get-SafeFiles $script:InputDir $videoExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.subtitled.mp4'} {
 param($source,$result,$file)
 $subs=@(Get-SafeFiles (Join-Path $script:InputDir 'Subtitles') @('.srt','.ass')|Where-Object BaseName -eq $file.BaseName)
 if($subs.Count -ne 1){throw 'Exactly one matching-basename SRT/ASS is required in Input\Subtitles.'}
 $text=[IO.File]::ReadAllText($subs[0].FullName,(New-Object Text.UTF8Encoding($false,$true)))
 if($subs[0].Extension -ieq '.srt' -and $text -notmatch '\d{2}:\d{2}:\d{2},\d{3}\s+-->'){throw 'Invalid SRT time syntax; expected UTF-8.'}
 if($subs[0].Extension -ieq '.ass' -and $text -notmatch '\[Events\]'){throw 'Invalid ASS Events section.'}
 $alias='subtitle'+$subs[0].Extension.ToLowerInvariant();[IO.File]::Copy($subs[0].FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
 Write-Host '[INFO] Arabic shaping requires libass and an Arabic font; inspect the rendered text.'
 Invoke-LocalFF @('-i',$source,'-map','0:v:0','-map','0:a:0?','-vf',('subtitles=filename='+$alias+':charenc=UTF-8'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-movflags','+faststart',$result)
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
