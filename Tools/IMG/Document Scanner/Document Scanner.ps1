param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
 Show-LocalTool 'Document Scanner' $PSScriptRoot $Mode 'magick' 'Detect a bright page on a contrasting background; preview first. Real four-corner perspective correction requires APPLY or explicit manual corners.'
 Add-Type -AssemblyName System.Drawing
 # Connected bright-paper component, conservative confidence, no external CV dependency.
 Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class ToolsBatPaper {
 public static double[] Detect(string path) {
  using(var original=new Bitmap(path)) {
   int w=Math.Min(800,original.Width),h=Math.Max(1,original.Height*w/original.Width);
   if(h>1000){h=1000;w=Math.Max(1,original.Width*h/original.Height);}
   using(var b=new Bitmap(original,w,h)) {
    int n=w*h;var mask=new byte[n];var queue=new int[n];int largest=0;double[] best=null;
    for(int y=0;y<h;y++)for(int x=0;x<w;x++){Color c=b.GetPixel(x,y);int lo=Math.Min(c.R,Math.Min(c.G,c.B)),hi=Math.Max(c.R,Math.Max(c.G,c.B));if(lo>=175 && hi-lo<80)mask[y*w+x]=1;}
    for(int seed=0;seed<n;seed++)if(mask[seed]==1){
     int head=0,tail=1;queue[0]=seed;mask[seed]=2;
     double minSum=1e9,maxSum=-1e9,minDiff=1e9,maxDiff=-1e9;var corners=new double[8];
     while(head<tail){int p=queue[head++],x=p%w,y=p/w;double sum=x+y,diff=x-y;
      if(sum<minSum){minSum=sum;corners[0]=x;corners[1]=y;}if(diff>maxDiff){maxDiff=diff;corners[2]=x;corners[3]=y;}
      if(sum>maxSum){maxSum=sum;corners[4]=x;corners[5]=y;}if(diff<minDiff){minDiff=diff;corners[6]=x;corners[7]=y;}
      if(x>0 && mask[p-1]==1){mask[p-1]=2;queue[tail++]=p-1;}if(x<w-1 && mask[p+1]==1){mask[p+1]=2;queue[tail++]=p+1;}
      if(y>0 && mask[p-w]==1){mask[p-w]=2;queue[tail++]=p-w;}if(y<h-1 && mask[p+w]==1){mask[p+w]=2;queue[tail++]=p+w;}
     }
     if(tail>largest){largest=tail;best=corners;}
    }
    if(best==null || largest<n*0.20 || largest>n*0.90)return null;
    double area=0;for(int i=0;i<4;i++){int j=(i+1)%4;area+=best[i*2]*best[j*2+1]-best[j*2]*best[i*2+1];}
    area=Math.Abs(area)/2;if(area<n*0.2 || area>n*0.92 || largest/area<0.60)return null;
    for(int i=0;i<4;i++){if(best[i*2]<3 || best[i*2]>w-4 || best[i*2+1]<3 || best[i*2+1]>h-4)return null;}
    // Verify darker surroundings outside each corner; a white photo/desk is ambiguous.
    double cx=0,cy=0;for(int i=0;i<4;i++){cx+=best[i*2]/4;cy+=best[i*2+1]/4;}
    int contrast=0;for(int i=0;i<4;i++){double dx=best[i*2]-cx,dy=best[i*2+1]-cy;double length=Math.Sqrt(dx*dx+dy*dy);int x=(int)Math.Round(best[i*2]+dx/length*8),y=(int)Math.Round(best[i*2+1]+dy/length*8);if(x>=0&&x<w&&y>=0&&y<h){Color c=b.GetPixel(x,y);if((c.R+c.G+c.B)/3<140)contrast++;}}
    if(contrast<3)return null;
    for(int i=0;i<4;i++){best[i*2]*=(double)original.Width/w;best[i*2+1]*=(double)original.Height/h;}return best;
   }
  }
 }
}
'@
 $choice=Read-LocalChoice $Mode @('Detect and publish preview only','Detect, preview, then APPLY correction','Manual four corners; explicit correction')
 $style=1;$pdf=$false
 if($choice -gt 1){$style=Read-LocalChoice 'Interactive' @('Color contrast','Grayscale contrast','Black and white adaptive threshold');$pdf=(Read-LocalChoice 'Interactive' @('PNG image','PNG plus image-only PDF')) -eq 2}
 if($choice -eq 3){Ensure-Directory (Join-Path $script:InputDir 'Corners')}
 $files=@(Get-SafeFiles $script:InputDir @('.png','.jpg','.jpeg','.bmp','.tif','.tiff','.webp'))
 Invoke-LocalBatch $files {param($f)$f.Name+$(if($choice -eq 1){'.scan-preview'}else{'.scanned'})} {
  param($source,$result,$file)
  $alias=[IO.Path]::GetFileName($source);$frames=(Invoke-Checked $script:Engine @('identify','-format','%n ',$alias)).Trim().Split(' ')[0];if([int]$frames -ne 1){throw 'One frame per input required.'}
  [void](Invoke-Checked $script:Engine @($alias,'-auto-orient','-background','white','-alpha','remove','-alpha','off','normalized.png'))
  $dims=(Invoke-Checked $script:Engine @('identify','-format','%w %h','normalized.png')).Trim().Split(' ');$w=[int]$dims[0];$h=[int]$dims[1]
  if($w -gt 12000 -or $h -gt 12000){throw 'Image dimensions exceed 12000 pixels.'}
  $corners=[ToolsBatPaper]::Detect((Join-Path $script:NativeWorkingDirectory 'normalized.png'));$method='Automatic bright-paper component'
  if($choice -eq 3){
   $config=Join-Path (Join-Path $script:InputDir 'Corners') ($file.Name+'.txt')
   if(Test-Path -LiteralPath $config -PathType Leaf){if((Get-Item -LiteralPath $config).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked corner files refused.'};$value=[IO.File]::ReadAllText($config).Trim()}
   else{Write-Host ('Use pixel coordinates AFTER EXIF orientation, image '+$w+' x '+$h);$value=Read-Host 'TLx,TLy TRx,TRy BRx,BRy BLx,BLy'}
   if($value -notmatch '^\d{1,5},\d{1,5} \d{1,5},\d{1,5} \d{1,5},\d{1,5} \d{1,5},\d{1,5}$'){throw 'Expected four x,y pairs: top-left top-right bottom-right bottom-left.'}
   $corners=@(($value -split '[, ]')|ForEach-Object{[double]$_});$method='Manual coordinates; explicit user choice'
  }
  if(-not $corners){
   [IO.File]::Copy((Join-Path $script:NativeWorkingDirectory 'normalized.png'),(Join-Path $result 'preview.png'),$false)
   [IO.File]::WriteAllText((Join-Path $result 'decision.txt'),'Uncertain page boundary: no crop or perspective correction performed. Use Manual four corners after reviewing preview.png. Coordinates refer to EXIF-normalized image.')
   if($choice -gt 1){throw 'Automatic detection uncertain: use the preview-only mode, then supply manual corners.'};Write-Host '[INFO] Uncertain boundary; preview only.';return
  }
  # Require a convex, clockwise quadrilateral and nontrivial dimensions.
  $area=0.0
  for($i=0;$i -lt 4;$i++){
   $j=($i+1)%4;$k=($i+2)%4;$x=$corners[$i*2];$y=$corners[$i*2+1]
   if($x -lt 0 -or $x -ge $w -or $y -lt 0 -or $y -ge $h){throw 'Corner outside normalized image.'}
   $cross=($corners[$j*2]-$x)*($corners[$k*2+1]-$corners[$j*2+1])-($corners[$j*2+1]-$y)*($corners[$k*2]-$corners[$j*2]);if($cross -le 0){throw 'Corners must form a convex clockwise quadrilateral in TL TR BR BL order.'}
   $area+=$x*$corners[$j*2+1]-$corners[$j*2]*$y
  }
  if($area/2 -lt $w*$h*0.05){throw 'Selected page area too small; refusing an unsafe crop.'}
  $coords=@(for($i=0;$i -lt 4;$i++){[Math]::Round($corners[$i*2]).ToString()+','+[Math]::Round($corners[$i*2+1]).ToString()})
  [void](Invoke-Checked $script:Engine @('normalized.png','-stroke','red','-strokewidth','4','-fill','none','-draw',('polygon '+($coords -join ' ')),'result/preview.png'))
  [IO.File]::WriteAllText((Join-Path $result 'corners.txt'),($coords -join ' '))
  @{Method=$method;Width=$w;Height=$h;Corners=$corners;Applied=$false}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $result 'decision.json') -Encoding UTF8
  $apply=$choice -eq 3
  if($choice -eq 2){Write-Host ('Inspect: '+(Join-Path $result 'preview.png'));$apply=(Read-Host 'Type APPLY to correct this copy') -ceq 'APPLY'}
  if(-not $apply){return}
  function Distance([int]$a,[int]$b){[Math]::Sqrt([Math]::Pow($corners[$a*2]-$corners[$b*2],2)+[Math]::Pow($corners[$a*2+1]-$corners[$b*2+1],2))}
  $ow=[int][Math]::Round([Math]::Max((Distance 0 1),(Distance 3 2)));$oh=[int][Math]::Round([Math]::Max((Distance 0 3),(Distance 1 2)))
  if($ow -lt 50 -or $oh -lt 50){throw 'Corrected page must be at least50x50.'}
  $mapping=$coords[0]+' 0,0 '+$coords[1]+' '+($ow-1)+',0 '+$coords[2]+' '+($ow-1)+','+($oh-1)+' '+$coords[3]+' 0,'+($oh-1)
  $args=@('normalized.png','-virtual-pixel','white','-define',('distort:viewport='+$ow+'x'+$oh+'+0+0'),'-distort','Perspective',$mapping,'+repage')
  if($style -eq 2){$args+=@('-colorspace','Gray','-contrast-stretch','1%x1%')}elseif($style -eq 3){$args+=@('-colorspace','Gray','-lat','31x31+10%')}else{$args+=@('-contrast-stretch','0.5%x0.5%')}
  $args+=@('-unsharp','0x0.7+0.6+0');if($style -eq 3){$args+=@('-threshold','50%')};$args+='result/scanned.png';[void](Invoke-Checked $script:Engine $args)
  if($pdf){[void](Invoke-Checked $script:Engine @('result/scanned.png','-units','PixelsPerInch','-density','150','result/scanned.pdf'))}
  @{Method=$method;Width=$w;Height=$h;Corners=$corners;Applied=$true;OutputWidth=$ow;OutputHeight=$oh;OCR=$false}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $result 'decision.json') -Encoding UTF8
 } -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
