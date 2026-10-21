param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\OCR.ps1')
try {
 if($Mode -ne 'Help'){$script:Magick=Require-Dependency 'magick';$ocr=Get-OCRConfiguration;if($Mode -eq 'Check'){Test-OCRLanguages $ocr 'ara+eng'}}
 Show-LocalTool 'Image OCR' $PSScriptRoot $Mode 'tesseract' 'Extract UTF-8 text from images using real Tesseract OCR; choose installed languages. Default ara+eng, automatic layout.'
 $settings=Select-OCRSettings $Mode $ocr
 $files=@(Get-SafeFiles $script:InputDir @('.png','.jpg','.jpeg','.bmp','.tif','.tiff','.webp'))
 Invoke-LocalBatch $files {param($f)$f.Name+'.ocr.txt'} {
  param($source,$result)
  $alias=[IO.Path]::GetFileName($source)
  $frames=(Invoke-Checked $script:Magick @('identify','-format','%n ',$alias)).Trim().Split(' ')[0];if([int]$frames -ne 1){throw 'One image/frame per input; use PDF OCR for multi-page documents.'}
  [void](Invoke-Checked $script:Magick @($alias,'-auto-orient','-background','white','-alpha','remove','-alpha','off','page.png'))
  $null=Invoke-OCRImage $ocr $settings 'page.png' 'recognized'
  [IO.File]::Copy((Join-Path $script:NativeWorkingDirectory 'recognized.txt'),$result,$false)
 }
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
