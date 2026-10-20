param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Empty Folders Report' $PSScriptRoot $Mode '' 'Empty Folders Report: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$null=Read-LocalChoice $Mode @('Report directly empty child folders; no deletion')
$destination=Join-Path $script:OutputDir 'empty-folders.csv'
if(Test-Path -LiteralPath $destination){Write-Host '[SKIPPED] empty-folders.csv exists.';exit 0}
$dirs=@(Get-SafeDirectories $script:InputDir)
if(-not $dirs.Count){Write-Host '[INFO] No supported input folders.';exit 0}
$rows=@(foreach($d in $dirs){if(-not @(Get-ChildItem -LiteralPath $d.FullName -Force|Where-Object Name -ne '.gitkeep').Count){[pscustomobject]@{Path=Get-RelativeName $script:InputDir $d.FullName;Empty=$true}}})
$work=New-WorkDirectory $script:OutputDir
try{
 $result=Join-Path $work 'report.csv'
 if($rows.Count){$rows|Export-Csv -LiteralPath $result -NoTypeInformation -Encoding UTF8}else{[IO.File]::WriteAllText($result,'"Path","Empty"')}
 Publish-File $result $destination
}finally{Remove-WorkDirectory $work $script:OutputDir}
Write-Host ('[SUCCESS] empty-folders.csv; empty folders: '+$rows.Count);Write-Host 'Total: 1 Successful: 1 Failed: 0 Skipped: 0'
exit 0
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
