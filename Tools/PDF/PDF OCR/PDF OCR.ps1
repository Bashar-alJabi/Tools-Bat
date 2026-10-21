param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\OCR.ps1')
try {
 if($Mode -ne 'Help'){$script:PDFEngine=Require-Dependency 'ghostscript';$script:QPDF=Require-Dependency 'qpdf';$script:Magick=Require-Dependency 'magick';$ocr=Get-OCRConfiguration;if($Mode -eq 'Check'){Test-OCRLanguages $ocr 'ara+eng'};if(-not (Test-Path -LiteralPath (Join-Path $ocr.Data 'pdf.ttf'))){throw 'Tesseract PDF font pdf.ttf missing; supply the full runtime package.'}}
 Show-LocalTool 'PDF OCR' $PSScriptRoot $Mode 'tesseract' 'Create searchable PDF copies: OCR only pages with no extracted text, keep existing text pages without duplicating their layer.'
 $settings=Select-OCRSettings $Mode $ocr
 $quality=Read-LocalChoice $Mode @('300 DPI (default)','200 DPI smaller raster','400 DPI detailed raster')
 $dpi=@(300,200,400)[$quality-1]
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
 Invoke-LocalBatch $files {param($f)$f.Name+'.ocr'} {
  param($source,$result)
  $encrypted=Invoke-Native $script:QPDF @('--is-encrypted','source.pdf');if($encrypted.Code -ne 2){throw 'Encrypted or invalid PDF refused; use PDF Unlock with the known password first.'}
  $count=Get-PDFCount 'source.pdf';$parts=@();$records=@()
  for($page=1;$page -le $count;$page++){
   $existing=Get-PDFText 'source.pdf' $page;$name='ocr'+$page+'.pdf'
   if($existing.Trim()){
    # qpdf preserves the original page's objects; no rasterization/second text layer.
    [void](Invoke-Checked $script:QPDF @('source.pdf','--pages','.',([string]$page),'--',$name));$status='Existing text retained; page not OCRed';$recognized=$existing
   }else{
    Render-PDFPage 'source.pdf' $page 'page.png' $dpi
    $recognized=Invoke-OCRImage $ocr $settings 'page.png' ('ocr'+$page) $true $dpi $true
    if(-not $recognized.Trim()){
     $minimum=(Invoke-Checked $script:Magick @('page.png','-colorspace','Gray','-format','%[fx:minima]','info:')).Trim()
     if([double]::Parse($minimum,[Globalization.CultureInfo]::InvariantCulture) -lt 0.9999){throw ('No text recognized on nonwhite page '+$page+'; no OCR success claimed.')}
     # Tesseract may legitimately return empty text for white pages.
     [void](Invoke-Checked $script:QPDF @('source.pdf','--pages','.',([string]$page),'--',('blank'+$page+'.pdf')));$name='blank'+$page+'.pdf';$status='White page retained; no text expected'
    }else{
     if((Get-PDFCount $name) -ne 1 -or -not (Get-PDFText $name 1).Trim()){throw ('OCR PDF has no searchable layer on page '+$page)}
     $status='OCR raster + searchable text layer'
    }
   }
   $parts+=$name
   [IO.File]::WriteAllText((Join-Path $result ('page-'+$page+'.txt')),$recognized,(New-Object Text.UTF8Encoding($false)))
   $records+=[pscustomobject]@{Page=$page;Status=$status;RecognizedCharacters=$recognized.Trim().Length;Language=$settings.Language;DPI=$dpi}
  }
  $merge=@('--empty','--pages');foreach($part in $parts){$merge+=@($part,'1')};$merge+=@('--','result/searchable.pdf');[void](Invoke-Checked $script:QPDF $merge)
  if((Get-PDFCount 'result/searchable.pdf') -ne $count){throw 'Searchable page count mismatch.'}
  $textPages=0
  for($page=1;$page -le $count;$page++){if($records[$page-1].Status -notlike 'White page*'){if(-not (Get-PDFText 'result/searchable.pdf' $page).Trim()){throw ('No extracted text in final page '+$page)};$textPages++}}
  if(-not $textPages){throw 'Document has only white pages; no searchable text or OCR success can be reported.'}
  $records|Export-Csv -LiteralPath (Join-Path $result 'pages.csv') -NoTypeInformation -Encoding UTF8
 } -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
