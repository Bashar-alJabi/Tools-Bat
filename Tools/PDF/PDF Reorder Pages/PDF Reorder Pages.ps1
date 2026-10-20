param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'PDF Reorder Pages' $PSScriptRoot $Mode 'ghostscript' 'PDF Reorder Pages: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

function PDF-Count([string]$Alias){
 $text=Invoke-Checked $script:Engine @('-q','-dSAFER','-dNODISPLAY',('--permit-file-read='+$Alias),'-c',('('+$Alias+') (r) file runpdfbegin pdfpagecount = quit'))
 $n=0;if(-not [int]::TryParse($text.Trim(),[ref]$n) -or $n -lt 1){throw 'No valid PDF page count.'};$n
}
function Parse-Pages([string]$Text,[int]$Count){
 if($Text.Length -gt 10000 -or $Text -notmatch '^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$'){throw 'Use page numbers/ranges such as 2,5,7-10 without spaces.'}
 $pages=New-Object 'Collections.Generic.List[int]'
 foreach($token in $Text.Split(',')){
  $range=$token.Split('-');$first=0;$last=0
  if(-not [int]::TryParse($range[0],[ref]$first)){throw 'Invalid page number.'}
  $last=$first;if($range.Count -eq 2 -and -not [int]::TryParse($range[1],[ref]$last)){throw 'Invalid range.'}
  if($first -lt 1 -or $last -lt $first -or $last -gt $Count){throw 'Page/range is outside the document or reversed.'}
  if(($pages.Count+$last-$first+1) -gt 1000){throw 'At most 1000 selected pages.'}
  for($p=$first;$p -le $last;$p++){if($pages.Contains($p)){throw 'Duplicate page number refused.'};$pages.Add($p)}
 }
 return ,$pages.ToArray()
}
$choice=Read-LocalChoice $Mode @('Reverse all pages','Custom complete permutation')
$selection='';if($choice -eq 2){$selection=Read-Host 'Every page once, e.g. 3,1,2'}
$files=@(Get-SafeFiles $script:InputDir @('.pdf'))
Invoke-LocalBatch $files {param($f) $f.Name+'.reordered.pdf'} {
 param($source,$result)
 $alias=[IO.Path]::GetFileName($source);$count=PDF-Count $alias;if($count -gt 1000){throw 'At most 1000 pages.'}
 $pages=if($choice -eq 1){@($count..1)}else{Parse-Pages $selection $count}
 if($pages.Count -ne $count){throw 'Reorder requires every page exactly once. Use PDF Extract Pages for a subset.'}
 # pdfwrite in some supported builds rejects non-increasing PageList at device
 # initialization. Export each requested page, then merge in explicit list order.
 $list=@();$i=0
 foreach($page in $pages){
  $i++;$name='selected'+$i+'.pdf'
  [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite',('-dFirstPage='+$page),('-dLastPage='+$page),('-sOutputFile='+$name),$alias));$list+=$name
 }
 [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'selected.txt'),$list,(New-Object Text.ASCIIEncoding))
 [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=result.pdf','@selected.txt'))
 if((PDF-Count 'result.pdf') -ne $count){throw 'Reordered page count mismatch.'}
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
