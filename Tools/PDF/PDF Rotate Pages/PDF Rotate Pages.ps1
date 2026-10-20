param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'PDF Rotate Pages' $PSScriptRoot $Mode 'ghostscript' 'PDF Rotate Pages: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
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
$choice=Read-LocalChoice $Mode @('All pages: 90 degrees clockwise','Selected pages and angle')
$selection='';$orientation=3
if($choice -eq 2){$selection=Read-Host 'Pages, e.g. 2,5-7';$angle=Read-LocalChoice 'Interactive' @('90 clockwise','180','270 clockwise');$orientation=@(3,2,1)[$angle-1]}
$files=@(Get-SafeFiles $script:InputDir @('.pdf'))
Invoke-LocalBatch $files {param($f) $f.Name+'.rotated.pdf'} {
 param($source,$result)
 $alias=[IO.Path]::GetFileName($source);$count=PDF-Count $alias;if($count -gt 200){throw 'Rotation rebuild limit: 200 pages.'}
 $pages=if($choice -eq 1){@(1..$count)}else{Parse-Pages $selection $count};$list=@()
 for($p=1;$p -le $count;$p++){
  $name='page'+$p+'.pdf';$o=if($p -in $pages){$orientation}else{0}
  [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dAutoRotatePages=/None',('-sPageList='+$p),('-sOutputFile='+$name),'-c',('<</Orientation '+$o+'>> setpagedevice'),'-f',$alias));$list+=$name
 }
 [IO.File]::WriteAllLines((Join-Path $script:NativeWorkingDirectory 'pages.txt'),$list,(New-Object Text.ASCIIEncoding))
 [void](Invoke-Checked $script:Engine @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-dAutoRotatePages=/None','-sOutputFile=result.pdf','@pages.txt'))
 if((PDF-Count 'result.pdf') -ne $count){throw 'Rotated page count mismatch.'}
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
