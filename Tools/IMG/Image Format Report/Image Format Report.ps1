param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Image Format Report' $PSScriptRoot $Mode 'magick' 'Image Format Report: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')

$null=Read-LocalChoice $Mode @('Collect image rows, totals, format counts and largest images')
$files=@(Get-SafeFiles $script:InputDir ($imageExt+@('.gif')))
Invoke-LocalBatch $files {'image-report'} {
 param($source,$result,$file,$all)
 $rows=@();$i=0
 foreach($f in $all){
  $i++;$alias='image'+$i+$f.Extension;[IO.File]::Copy($f.FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
  $info=(Invoke-Checked $script:Engine @('identify','-format','%m|%w|%h|%n',($alias+'[0]'))).Trim().Split('|')
  $rows+=[pscustomobject]@{Name=$f.Name;Format=$info[0];Width=[int]$info[1];Height=[int]$info[2];FirstFramePixels=([long]$info[1]*[long]$info[2]);Bytes=$f.Length}
 }
 $rows|Export-Csv -LiteralPath (Join-Path $result 'images.csv') -NoTypeInformation -Encoding UTF8
 $summary=[pscustomobject]@{Count=$rows.Count;TotalBytes=[long]($rows|Measure-Object Bytes -Sum).Sum;CountsByFormat=@($rows|Group-Object Format|Select-Object Name,Count);LargestByBytes=@($rows|Sort-Object Bytes -Descending|Select-Object -First 10);LargestByPixels=@($rows|Sort-Object FirstFramePixels -Descending|Select-Object -First 10)}
 $summary|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $result 'summary.json') -Encoding UTF8
} -Aggregate -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
