param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image Duplicates' $PSScriptRoot $Mode 'magick' 'Image Duplicates: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$choice=Read-LocalChoice $Mode @('Visual hash distance <= 5','Distance <= 10','Custom distance 0-16')
$threshold=if($choice -eq 2){10}else{5}
if($choice -eq 3){$n=Read-LocalNumber 'Maximum Hamming distance (integer 0-16)' 0 16;if($n -notmatch '^\d+$'){throw 'Integer required.'};$threshold=[int]$n}
$files=@(Get-SafeFiles $script:InputDir $imageExt)
Invoke-LocalBatch $files {'similarity'} {
 param($source,$result,$file,$all)
 if($all.Count -gt 500){throw 'At most 500 images; pairwise comparison is quadratic.'}
 $items=@();$i=0
 foreach($f in $all){
  $alias='image'+$i+$f.Extension;[IO.File]::Copy($f.FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
  $frames=Invoke-Checked $script:Engine @('identify','-format','%n ',$alias)
  if([int]($frames.Trim().Split(' ')[0]) -ne 1){throw 'Single-frame images only.'}
  [void](Invoke-Checked $script:Engine @($alias,'-auto-orient','-background','white','-alpha','remove','-colorspace','Gray','-resize','9x8!','-depth','8','gray:pixels.bin'))
  $pixels=[IO.File]::ReadAllBytes((Join-Path $script:NativeWorkingDirectory 'pixels.bin'));$bits=@()
  for($y=0;$y -lt 8;$y++){for($x=0;$x -lt 8;$x++){$bits+=($pixels[$y*9+$x] -gt $pixels[$y*9+$x+1])}}
  $items+= [pscustomobject]@{Id=$i;Path=$f.Name;SHA256=(Get-FileHash -LiteralPath $f.FullName).Hash;Bits=$bits};$i++
 }
 $parent=@{};foreach($item in $items){$parent[$item.Id]=$item.Id}
 function Find([int]$x){while($parent[$x] -ne $x){$x=$parent[$x]};$x}
 $pairs=@(for($i=0;$i -lt $items.Count;$i++){for($j=$i+1;$j -lt $items.Count;$j++){
  $distance=0;for($k=0;$k -lt 64;$k++){if($items[$i].Bits[$k] -ne $items[$j].Bits[$k]){$distance++}}
  $exact=$items[$i].SHA256 -eq $items[$j].SHA256
  if($exact -or $distance -le $threshold){
   $parent[(Find $j)]=Find $i
   [pscustomobject]@{Left=$items[$i].Path;Right=$items[$j].Path;Match=$(if($exact){'BytesIdentical'}else{'Approximate'});Hamming=$distance;HashSimilarityPercent=[Math]::Round(100*(64-$distance)/64,2)}
  }
 }})
 if($pairs.Count){$pairs|Export-Csv -LiteralPath (Join-Path $result 'pairs.csv') -NoTypeInformation -Encoding UTF8}else{[IO.File]::WriteAllText((Join-Path $result 'pairs.csv'),'"Left","Right","Match","Hamming","HashSimilarityPercent"')}
 $items|ForEach-Object{[pscustomobject]@{Group=(Find $_.Id)+1;Path=$_.Path;SHA256=$_.SHA256}}|Export-Csv -LiteralPath (Join-Path $result 'images.csv') -NoTypeInformation -Encoding UTF8
 Write-Host 'Approximate matches require visual review; hash similarity is not a probability.'
} -Aggregate -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
