param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 Show-LocalTool 'PDF Add Page Numbers' $PSScriptRoot $Mode 'ghostscript' 'Add visible page numbers to new PDF copies. Default bottom center, start 1, skip 0.'
 $script:PDFEngine=$script:Engine
 $position=Read-LocalChoice $Mode @('Bottom center','Bottom left','Bottom right','Top center','Top left','Top right')
 $start=1;$skip=0
 if($Mode -ne 'Defaults'){$start=Read-LocalNumber 'Start integer (0-999999)' 0 999999;$skip=Read-LocalNumber 'Skip first N pages (0-999)' 0 999;if($start -notmatch '^\d+$' -or $skip -notmatch '^\d+$'){throw 'Integer values required.'}}
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
 Invoke-LocalBatch $files {param($f)$f.Name+'.numbered.pdf'} {
  param($source,$result)
  $count=Get-PDFCount 'source.pdf';if([int]$skip -ge $count){throw 'Skip count leaves no page to number.'}
  $x=switch($position){2{'18'};5{'18'};3{'pw 18 sub tw sub'};6{'pw 18 sub tw sub'};default{'pw tw sub 2 div'}}
  $y=if($position -ge 4){'ph 30 sub'}else{'18'}
  $program='/TBpage 0 def << /EndPage { exch pop 2 ne { userdict /TBpage TBpage 1 add put TBpage '+$skip+' gt { gsave initgraphics /pw currentpagedevice /PageSize get 0 get def /ph currentpagedevice /PageSize get 1 get def /Helvetica findfont 12 scalefont setfont /s TBpage '+$skip+' sub '+$start+' add 1 sub 20 string cvs def /tw s stringwidth pop def '+$x+' '+$y+' moveto 0 setgray s show grestore } if true } { false } ifelse } bind >> setpagedevice'
  [void](Invoke-Checked $script:PDFEngine @('-q','-dSAFER','-dPDFSTOPONERROR','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dAutoRotatePages=/None','-sOutputFile=result.pdf','-c',$program,'-f','source.pdf'))
  if((Get-PDFCount 'result.pdf') -ne $count){throw 'Numbering lost pages.'}
 }
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
