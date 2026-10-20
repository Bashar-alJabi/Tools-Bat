param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image to PDF' $PSScriptRoot $Mode 'magick' 'Image to PDF: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('A4 portrait, 150 DPI','A4 landscape, 150 DPI','Original pixel dimensions at 150 DPI')
$files=@(Get-SafeFiles $script:InputDir $imageExt)
Invoke-LocalBatch $files {'images.pdf'} {
 param($source,$result,$file,$all)
 if($all.Count -gt 200){throw 'At most 200 images.'}
 $aliases=@();$i=0
 foreach($f in $all){
  $i++;$alias='page'+$i+$f.Extension;[IO.File]::Copy($f.FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
  $frames=Invoke-Checked $script:Engine @('identify','-format','%n ',$alias);if([int]($frames.Trim().Split(' ')[0]) -ne 1){throw 'Single-frame images only.'}
  $page='page'+$i+'.jpg';$args=@($alias,'-auto-orient','-background','white','-alpha','remove','-alpha','off')
  if($choice -ne 3){$size=if($choice -eq 2){'1754x1240'}else{'1240x1754'};$args+=@('-resize',($size+'>'),'-gravity','center','-extent',$size)}
  [void](Invoke-Checked $script:Engine ($args+@('-quality','95','-units','PixelsPerInch','-density','150',$page)));$aliases+=$page
 }
 [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'pages.txt'),$aliases,(New-Object Text.ASCIIEncoding))
 [void](Invoke-Checked $script:Engine @('-units','PixelsPerInch','-density','150','@pages.txt','-adjoin','result.pdf'))
} -Aggregate
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
