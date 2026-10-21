param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 if($Mode -ne 'Help'){$script:Magick=Require-Dependency 'magick'}
 Show-LocalTool 'PDF Compare' $PSScriptRoot $Mode 'ghostscript' 'Compare one PDF in Input/Left and one in Input/Right: page counts, exact extracted text, and 120 DPI rendered pixels.'
 $script:PDFEngine=$script:Engine
 $null=Read-LocalChoice $Mode @('Compare text and rendered pixels at 120 DPI')
 Ensure-Directory (Join-Path $script:InputDir 'Left');Ensure-Directory (Join-Path $script:InputDir 'Right')
 $left=@(Get-SafeFiles (Join-Path $script:InputDir 'Left') @('.pdf'));$right=@(Get-SafeFiles (Join-Path $script:InputDir 'Right') @('.pdf'))
 if(-not $left.Count -and -not $right.Count){Write-Host '[INFO] No supported input files.';exit 0}
 if($left.Count -ne 1 -or $right.Count -ne 1){throw 'Exactly one PDF is required in each Left/Right folder.'}
 $files=@($left[0],$right[0])
 Invoke-LocalBatch $files {'pdf-comparison'} {
  param($source,$result,$file,$all)
  [IO.File]::Copy($all[0].FullName,(Join-Path $script:NativeWorkingDirectory 'left.pdf'),$false);[IO.File]::Copy($all[1].FullName,(Join-Path $script:NativeWorkingDirectory 'right.pdf'),$false)
  $a=Get-PDFCount 'left.pdf';$b=Get-PDFCount 'right.pdf'
  $rows=@(for($p=1;$p -le [Math]::Max($a,$b);$p++){
   if($p -gt [Math]::Min($a,$b)){[pscustomobject]@{Page=$p;Text='Missing page on one side';Visual='Missing page';NormalizedRMSE=''};continue}
   $ta=Get-PDFText 'left.pdf' $p;$tb=Get-PDFText 'right.pdf' $p
   Render-PDFPage 'left.pdf' $p 'left.png';Render-PDFPage 'right.pdf' $p 'right.png'
   $da=(Invoke-Checked $script:Magick @('identify','-format','%w %h','left.png')).Trim();$db=(Invoke-Checked $script:Magick @('identify','-format','%w %h','right.png')).Trim()
   $metric='';$visual='Different dimensions'
   if($da -eq $db){$r=Invoke-Native $script:Magick @('compare','-metric','RMSE','left.png','right.png',('result/diff-'+$p+'.png'));if($r.Code -notin 0,1){throw 'Pixel comparison failed.'};$visual=if($r.Code -eq 0){'Identical pixels'}else{'Different pixels'};$metric=$r.Err.Trim()}
   else{[void](Invoke-Checked $script:Magick @('left.png',('result/left-'+$p+'.png')));[void](Invoke-Checked $script:Magick @('right.png',('result/right-'+$p+'.png')))}
   [pscustomobject]@{Page=$p;Text=$(if(-not $ta.Trim() -and -not $tb.Trim()){'Both have no text; OCR needed'}elseif($ta -ceq $tb){'Identical extracted text'}else{'Different extracted text'});Visual=$visual;NormalizedRMSE=$metric}
  })
  $rows|Export-Csv -LiteralPath (Join-Path $result 'pages.csv') -NoTypeInformation -Encoding UTF8
  @{Left=$all[0].Name;Right=$all[1].Name;LeftPages=$a;RightPages=$b;DPI=120;Caution='Rendered differences and extracted-text differences measure different things. Extraction order is not guaranteed.'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $result 'summary.json') -Encoding UTF8
 } -Aggregate -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
