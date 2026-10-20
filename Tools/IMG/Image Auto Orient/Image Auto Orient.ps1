param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image Auto Orient' $PSScriptRoot $Mode 'magick' 'Image Auto Orient: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$null=Read-LocalChoice $Mode @('Correct EXIF orientation; otherwise make a byte-identical copy')
$files=@(Get-SafeFiles $script:InputDir $imageExt)
Invoke-LocalBatch $files {param($f) $f.Name+'.oriented'+$f.Extension} {
 param($source,$result)
 $alias=[IO.Path]::GetFileName($source)
 $info=(Invoke-Checked $script:Engine @('identify','-format','%n %[orientation]',$alias)).Trim().Split(' ')
 if([int]$info[0] -ne 1){throw 'Single-frame images only.'}
 if($info[1] -in @('Undefined','TopLeft')){[IO.File]::Copy($source,$result,$false);Write-Host '[INFO] No correction required; exact bytes copied.'}
 else{[void](Invoke-Checked $script:Engine @($alias,'-auto-orient',[IO.Path]::GetFileName($result)))}
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
