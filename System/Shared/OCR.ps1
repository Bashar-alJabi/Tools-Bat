# One OCR engine/language implementation for both image and PDF tools.
function Invoke-TesseractData([string]$Executable,[string]$Data,[string[]]$Arguments) {
 # This Windows build has narrow-character filesystem paths for --tessdata-dir.
 # Windows starts the process in the Unicode directory; the engine only sees '.'.
 $previous=Get-Variable NativeWorkingDirectory -Scope Script -ErrorAction SilentlyContinue
 $previousValue=if($previous){$previous.Value}else{$null}
 try{$script:NativeWorkingDirectory=$Data;Invoke-Native $Executable (@('--tessdata-dir','.')+$Arguments) 30000}
 finally{if($previous){$script:NativeWorkingDirectory=$previousValue}else{Remove-Variable NativeWorkingDirectory -Scope Script -ErrorAction SilentlyContinue}}
}
function Get-OCRConfiguration {
 $engine=Get-Dependency 'tesseract';if(-not $engine){throw 'Tesseract 5+ is missing. Run START_HERE; no download was started.'}
 $local=Join-Path $script:ProjectRoot 'System\Bin\Tesseract\tessdata'
 $adjacent=Join-Path ([IO.Path]::GetDirectoryName($engine.Path)) 'tessdata'
 $data=if(Test-Path -LiteralPath $local -PathType Container){$local}else{$adjacent}
 if(-not (Test-Path -LiteralPath $data -PathType Container)){throw 'No tessdata directory found beside the complete local/system Tesseract tree.'}
 Ensure-Directory $data
 $r=Invoke-TesseractData $engine.Path $data @('--list-langs')
 if($r.Code -ne 0){throw 'Tesseract could not list languages.'}
 $languages=@(($r.Out -split '[\r\n]+')|Where-Object{$_ -match '^[a-zA-Z0-9_]+$'})
 [pscustomobject]@{Engine=$engine;Data=$data;Languages=$languages}
}
function Test-OCRLanguages($Configuration,[string]$Languages) {
 if($Languages -notmatch '^[a-zA-Z0-9_]+(?:\+[a-zA-Z0-9_]+)*$'){throw 'Use installed language codes joined by +, for example ara+eng.'}
 foreach($language in $Languages.Split('+')){
  if($language -notin $Configuration.Languages -or $language -eq 'osd'){throw ('Missing/non-text OCR language: '+$language)}
  $r=Invoke-TesseractData $Configuration.Engine.Path $Configuration.Data @('-l',$language,'--oem','1','--print-parameters')
  if($r.Code -ne 0 -or $r.Err -match 'Error opening data|Failed loading|Could not initialize'){throw ('Language cannot initialize: '+$language)}
 }
}
function Select-OCRSettings([string]$Mode,$Configuration) {
 Write-Host ('Installed languages: '+($Configuration.Languages -join ', '))
 $choice=Read-LocalChoice $Mode @('Arabic + English (ara+eng)','Arabic (ara)','English (eng)','Other installed text languages')
 $language=@('ara+eng','ara','eng','')[$choice-1];if($choice -eq 4){$language=Read-Host 'Installed codes joined by +'}
 Test-OCRLanguages $Configuration $language
 $layout=Read-LocalChoice $Mode @('Automatic layout; retry a single block if no text is found','Automatic layout with orientation detection (requires osd)','One uniform text block (PSM 6)')
 if($layout -eq 2 -and 'osd' -notin $Configuration.Languages){throw 'osd.traineddata is required for orientation detection.'}
 [pscustomobject]@{Language=$language;PSM=$(if($layout -eq 2){'1'}elseif($layout -eq 3){'6'}else{'3'})}
}
function Invoke-OCRImage($Configuration,$Settings,[string]$Alias,[string]$Base,[bool]$PDF=$false,[int]$DPI=300,[bool]$AllowEmpty=$false) {
 $data=Join-Path $script:NativeWorkingDirectory 'ocr-data';Ensure-Directory $data
 $models=@($Settings.Language.Split('+'));if($Settings.PSM -eq '1'){$models+='osd'}
 foreach($model in $models){$filename=$model+'.traineddata';$target=Join-Path $data $filename;if(-not (Test-Path -LiteralPath $target)){[IO.File]::Copy((Join-Path $Configuration.Data $filename),$target,$false)}}
 if($PDF -and -not (Test-Path -LiteralPath (Join-Path $data 'pdf.ttf'))){[IO.File]::Copy((Join-Path $Configuration.Data 'pdf.ttf'),(Join-Path $data 'pdf.ttf'),$false)}
 $psm=$Settings.PSM
 if($psm -eq '1'){
  $osd=Invoke-Native $Configuration.Engine.Path @($Alias,'stdout','--tessdata-dir','ocr-data','-l','osd','--psm','0')
  $orientation=$osd.Out+$osd.Err;$rotate=0;$confidence=0.0
  if($orientation -match '(?m)^Rotate: (0|90|180|270)\s*$'){$rotate=[int]$Matches[1]}else{throw 'Orientation detection uncertain or insufficient text; choose layout without orientation, or rotate a copy manually.'}
  if($orientation -match '(?m)^Orientation confidence: ([0-9.]+)'){$confidence=[double]::Parse($Matches[1],[Globalization.CultureInfo]::InvariantCulture)}
  if($osd.Code -ne 0 -or $confidence -lt 5){throw ('Orientation confidence too low ('+$confidence+'); no rotation/recognition published. Choose layout without orientation or rotate a copy manually.')}
  Write-Host ('[INFO] Orientation: rotate '+$rotate+' degrees; confidence '+$confidence+'. Review the recognized text.')
  if($rotate){[void](Invoke-Checked $script:Magick @($Alias,'-rotate',([string]$rotate),'ocr-upright.png'));$Alias='ocr-upright.png'}
  $psm='3'
 }
 $arguments=@($Alias,$Base,'--tessdata-dir','ocr-data','-l',$Settings.Language,'--oem','1','--psm',$psm,'--dpi',([string]$DPI),'-c','tessedit_create_txt=1')
 if($PDF){$arguments+=@('-c','tessedit_create_pdf=1')}
 $r=Invoke-Native $Configuration.Engine.Path $arguments
 if($r.Code -ne 0){throw ('OCR failed: '+$r.Err)}
 $path=Join-Path $script:NativeWorkingDirectory ($Base+'.txt')
 if(-not [IO.File]::Exists($path)){throw 'OCR did not create UTF-8 text.'}
 $text=[IO.File]::ReadAllText($path,(New-Object Text.UTF8Encoding($false,$true)))
 if([string]::IsNullOrWhiteSpace($text) -and $Settings.PSM -eq '3'){
  Write-Host '[INFO] Automatic layout found no text; retrying as one uniform block (PSM 6). Review recognition order and accuracy.'
  $retry=[pscustomobject]@{Language=$Settings.Language;PSM='6'}
  $text=Invoke-OCRImage $Configuration $retry $Alias $Base $PDF $DPI $AllowEmpty
 }
 if([string]::IsNullOrWhiteSpace($text) -and -not $AllowEmpty){throw 'No text recognized; no success claimed. Try a clearer image, language or page layout.'}
 $text
}
