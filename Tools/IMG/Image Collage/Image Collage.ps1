param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image Collage' $PSScriptRoot $Mode 'magick' 'Image Collage: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('Large left image and two stacked right images','Large top image and two bottom images','Custom left layout')
$width=1200;$gap=20;$color='#FFFFFF'
if($choice -eq 3){
 $n=Read-LocalNumber 'Canvas width, integer 400-6000' 400 6000;if($n -notmatch '^\d+$'){throw 'Integer width required.'};$width=[int]$n
 $n=Read-LocalNumber 'Gap pixels, integer 0-100' 0 100;if($n -notmatch '^\d+$'){throw 'Integer gap required.'};$gap=[int]$n
 $color=Read-Host 'Background #RRGGBB';if($color -notmatch '^#[A-Fa-f0-9]{6}$'){throw 'Expected #RRGGBB.'}
}
$files=@(Get-SafeFiles $script:InputDir $imageExt)
Invoke-LocalBatch $files {'collage.png'} {
 param($source,$result,$file,$all)
 if($all.Count -ne 3){throw 'Exactly three images are required, ordered by filename.'}
 $height=if($choice -eq 2){1000}else{[int]($width*2/3)}
 $a=[int](($width-3*$gap)*2/3);$b=$width-3*$gap-$a;$c=[int](($height-3*$gap)/2)
 if($choice -eq 2){$boxes=@(@(1160,580,20,20),@(570,360,20,620),@(570,360,610,620))}
 else{$boxes=@(@($a,($height-2*$gap),$gap,$gap),@($b,$c,($a+2*$gap),$gap),@($b,$c,($a+2*$gap),($c+2*$gap)))}
 [void](Invoke-Checked $script:Engine @('-size',($width.ToString()+'x'+$height),('xc:'+$color),'canvas.png'))
 for($i=0;$i -lt 3;$i++){
  $alias='image'+$i+$all[$i].Extension;[IO.File]::Copy($all[$i].FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
  $frames=Invoke-Checked $script:Engine @('identify','-format','%n ',$alias);if([int]($frames.Trim().Split(' ')[0]) -ne 1){throw 'Single-frame images only.'}
  $box=$boxes[$i];$size=[string]$box[0]+'x'+$box[1]
  [void](Invoke-Checked $script:Engine @($alias,'-auto-orient','-resize',($size+'^'),'-gravity','center','-extent',$size,'tile.png'))
  [void](Invoke-Checked $script:Engine @('canvas.png','tile.png','-gravity','northwest','-geometry',('+'+$box[2]+'+'+$box[3]),'-composite','canvas-next.png'))
  [IO.File]::Delete((Join-Path $script:NativeWorkingDirectory 'canvas.png'));[IO.File]::Move((Join-Path $script:NativeWorkingDirectory 'canvas-next.png'),(Join-Path $script:NativeWorkingDirectory 'canvas.png'))
 }
 [IO.File]::Move((Join-Path $script:NativeWorkingDirectory 'canvas.png'),$result)
} -Aggregate
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
