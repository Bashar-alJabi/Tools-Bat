param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 if($Mode -ne 'Help'){$script:PDFEngine=Require-Dependency 'ghostscript';$script:Magick=Require-Dependency 'magick';Add-Type -AssemblyName System.Drawing}
 Show-LocalTool 'PDF Watermark' $PSScriptRoot $Mode 'qpdf' 'Overlay text on a new PDF without rasterizing source pages. Default DRAFT, diagonal, 36pt, 25% opacity.'
 $choice=Read-LocalChoice $Mode @('DRAFT diagonal on all pages','Custom text, position, size, opacity and pages')
 $text='DRAFT';$position=1;$size=36;$opacity=0.25;$selection='all'
 if($choice -eq 2){
  $text=Read-Host 'Watermark text';if([string]::IsNullOrWhiteSpace($text) -or $text.Length -gt 120){throw 'Use 1-120 visible characters.'}
  $position=Read-LocalChoice 'Interactive' @('Diagonal center','Center','Top center','Bottom center')
  $size=[double](Read-LocalNumber 'Font size in points (8-120)' 8 120);$opacity=[double]::Parse((Read-LocalNumber 'Opacity (0.05-1)' 0.05 1),[Globalization.CultureInfo]::InvariantCulture)
  $selection=Read-Host 'Pages: all or e.g. 2,5-7'
 }
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
 Invoke-LocalBatch $files {param($f)$f.Name+'.watermarked.pdf'} {
  param($source,$result)
  $count=Get-PDFCount 'source.pdf';$pages=@((Get-PDFSelection $selection $count)|Sort-Object);$stamps=@()
  for($p=1;$p -le $count;$p++){
   if($p -notin $pages){continue}
   Render-PDFPage 'source.pdf' $p 'geometry.png' 72
   $dims=(Invoke-Checked $script:Magick @('identify','-format','%w %h','geometry.png')).Trim().Split(' ');$w=[int]$dims[0]*2;$h=[int]$dims[1]*2
   if($w -gt 10000 -or $h -gt 10000 -or $w -lt 72 -or $h -lt 72){throw 'Page dimensions outside safe stamp limits.'}
   $bitmap=New-Object Drawing.Bitmap($w,$h);$graphics=[Drawing.Graphics]::FromImage($bitmap);$font=New-Object Drawing.Font('Segoe UI',([single]($size*2)),[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel);$brush=New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb([int](255*$opacity),0,0,0));$format=New-Object Drawing.StringFormat
   try {
    $graphics.Clear([Drawing.Color]::Transparent);$graphics.TextRenderingHint=[Drawing.Text.TextRenderingHint]::AntiAliasGridFit;$format.Alignment=[Drawing.StringAlignment]::Center;$format.LineAlignment=[Drawing.StringAlignment]::Center
    if($text -match '[\u0600-\u06ff]'){$format.FormatFlags=[Drawing.StringFormatFlags]::DirectionRightToLeft}
    if($p -in $pages){
     if($position -eq 1){$graphics.TranslateTransform($w/2,$h/2);$graphics.RotateTransform(-35);$rect=New-Object Drawing.RectangleF((-$w/2),(-$h/2),$w,$h)}
     elseif($position -eq 3){$rect=New-Object Drawing.RectangleF(12,12,($w-24),([Math]::Min($h-24,$size*4)))}
     elseif($position -eq 4){$rect=New-Object Drawing.RectangleF(12,($h-$size*4-12),($w-24),($size*4))}
     else{$rect=New-Object Drawing.RectangleF(12,12,($w-24),($h-24))}
     # Refuse clipped text instead of silently truncating the watermark.
     $measure=$graphics.MeasureString($text,$font,[int]$rect.Width,$format);if($measure.Height -gt $rect.Height -or $measure.Width -gt $rect.Width){throw 'Text does not fit this page; reduce the font/text length.'}
     $graphics.DrawString($text,$font,$brush,$rect,$format)
    }
    $bitmap.SetResolution(144,144);$bitmap.Save((Join-Path $script:NativeWorkingDirectory 'stamp.png'),[Drawing.Imaging.ImageFormat]::Png)
   }finally{$format.Dispose();$brush.Dispose();$font.Dispose();$graphics.Dispose();$bitmap.Dispose()}
   $name='stamp'+$p+'.pdf';[void](Invoke-Checked $script:Magick @('stamp.png','-units','PixelsPerInch','-density','144',$name));$stamps+=$name
  }
  # Keep the alpha masks in the stamp PDFs. Re-rendering with pdfwrite can
  # introduce a page background; qpdf copies the objects without flattening.
  $merge=@('--empty','--pages');foreach($stamp in $stamps){$merge+=@($stamp,'1')};$merge+=@('--','stamps.pdf')
  [void](Invoke-Checked $script:Engine $merge)
  [void](Invoke-Checked $script:Engine @('source.pdf','--overlay','stamps.pdf',('--to='+($pages -join ',')),'--','result.pdf'))
  if((Get-PDFCount 'result.pdf') -ne $count){throw 'Watermark page count mismatch.'}
 }
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
