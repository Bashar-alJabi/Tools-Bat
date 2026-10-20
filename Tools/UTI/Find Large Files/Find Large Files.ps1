param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Find Large Files' $PSScriptRoot $Mode '' 'Find Large Files: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$choice=Read-LocalChoice $Mode @('Largest 20 files and cumulative folder sizes in Input','Custom read-only folder scope and top count')
$scope=$script:InputDir;$top=20
if($choice -eq 2){$scope=Read-Host 'Folder path to inspect (read only)';$n=Read-LocalNumber 'Top file count, integer 1-1000' 1 1000;if($n -notmatch '^\d+$'){throw 'Integer count required.'};$top=[int]$n}
if(-not (Test-Path -LiteralPath $scope -PathType Container)){throw 'Scope folder does not exist.'}
$scope=[IO.Path]::GetFullPath($scope);Ensure-Directory $scope
$destination=Join-Path $script:OutputDir 'large-files'
if(Test-Path -LiteralPath $destination){Write-Host '[SKIPPED] large-files exists.';exit 0}
if($destination.Length -gt 200){throw 'Use a shorter project path (report folder base <=200 characters).'}
$files=@(Get-SafeFiles $scope $null -Recurse|Where-Object {-not $_.FullName.StartsWith($script:OutputDir+'\',[StringComparison]::OrdinalIgnoreCase)})
if(-not $files.Count){Write-Host '[INFO] No supported input files.';exit 0}
$folders=@{};$folders[$scope.TrimEnd('\')]=[long]0
foreach($d in (Get-SafeDirectories $scope)){if($d.FullName -ne $script:OutputDir -and -not $d.FullName.StartsWith($script:OutputDir+'\',[StringComparison]::OrdinalIgnoreCase)){$folders[$d.FullName.TrimEnd('\')]=[long]0}}
foreach($f in $files){
 $dir=$f.DirectoryName
 while($dir -and ($dir.TrimEnd('\') -eq $scope.TrimEnd('\') -or $dir.StartsWith($scope.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase))){$key=$dir.TrimEnd('\');if($folders.ContainsKey($key)){$folders[$key]+=$f.Length};$dir=[IO.Path]::GetDirectoryName($dir)}
}
$work=New-WorkDirectory $script:OutputDir
try{
 $result=Join-Path $work 'result';Ensure-Directory $result
 $files|Sort-Object Length -Descending|Select-Object -First $top @{n='Path';e={Get-RelativeName $scope $_.FullName}},@{n='Bytes';e={$_.Length}}|Export-Csv -LiteralPath (Join-Path $result 'largest-files.csv') -NoTypeInformation -Encoding UTF8
 @($folders.GetEnumerator()|ForEach-Object{[pscustomobject]@{Path=$(if($_.Key -eq $scope.TrimEnd('\')){'.'}else{Get-RelativeName $scope $_.Key});CumulativeBytes=$_.Value}})|Sort-Object CumulativeBytes -Descending|Export-Csv -LiteralPath (Join-Path $result 'folders.csv') -NoTypeInformation -Encoding UTF8
 [pscustomobject]@{Scope=$scope;Files=$files.Count;TotalLogicalBytes=[long]($files|Measure-Object Length -Sum).Sum;Top=$top;ReparsePointsFollowed=$false}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $result 'summary.json') -Encoding UTF8
 [IO.Directory]::Move($result,$destination)
}finally{Remove-WorkDirectory $work $script:OutputDir}
Write-Host '[SUCCESS] large-files';Write-Host 'Total: 1 Successful: 1 Failed: 0 Skipped: 0'
exit 0
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
