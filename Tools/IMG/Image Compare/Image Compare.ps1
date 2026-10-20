param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image Compare' $PSScriptRoot $Mode 'magick' 'Image Compare: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$null=Read-LocalChoice $Mode @('Compare one image from Left with one from Right')
$left=@(Get-SafeFiles (Join-Path $script:InputDir 'Left') $imageExt);$right=@(Get-SafeFiles (Join-Path $script:InputDir 'Right') $imageExt)
if(-not $left.Count -and -not $right.Count){Write-Host '[INFO] No supported input files.';exit 0}
if($left.Count -ne 1 -or $right.Count -ne 1){throw 'Exactly one image in Input\Left and one in Input\Right are required.'}
$files=@($left[0],$right[0])
Invoke-LocalBatch $files {'difference'} {
 param($source,$result,$file,$all)
 $aliases=@();$dimensions=@();$i=0
 foreach($f in $all){$i++;$alias='image'+$i+$f.Extension;[IO.File]::Copy($f.FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
  $info=(Invoke-Checked $script:Engine @('identify','-format','%w %h %n',$alias)).Trim().Split(' ')
  if([int]$info[2] -ne 1){throw 'Single-frame images only.'};$dimensions+=($info[0]+'x'+$info[1]);$aliases+=$alias
 }
 if($dimensions[0] -ne $dimensions[1]){throw 'Image dimensions differ; resize copies explicitly before comparison.'}
 $compare=Invoke-Native $script:Engine @('compare','-metric','RMSE',$aliases[0],$aliases[1],'result/diff.png')
 if($compare.Code -notin @(0,1) -or $compare.Err -notmatch '\(([0-9.eE+-]+)\)'){throw ('Comparison failed: '+$compare.Err)}
 [pscustomobject]@{Left=$all[0].Name;Right=$all[1].Name;Dimensions=$dimensions[0];NormalizedRMSE=$Matches[1];IdenticalPixels=($compare.Code -eq 0)}|Export-Csv -LiteralPath (Join-Path $result 'comparison.csv') -NoTypeInformation -Encoding UTF8
} -Aggregate -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
