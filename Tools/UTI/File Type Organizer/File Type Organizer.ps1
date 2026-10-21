param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
 Show-LocalTool 'File Type Organizer' $PSScriptRoot $Mode '' 'Copy a recursive Input tree into semantic media/document categories, preserving subfolders and verifying hashes.'
 $choice=Read-LocalChoice $Mode @('Include subfolders','Top-level files only')
 $files=@(Get-SafeFiles $script:InputDir $null -Recurse:($choice -eq 1))
 $types=@{Images=@('.jpg','.jpeg','.png','.gif','.bmp','.tif','.tiff','.webp','.heic','.avif','.svg','.ico','.raw','.dng');Videos=@('.mp4','.mkv','.avi','.mov','.webm','.m4v','.wmv','.mpeg','.mpg','.ts');Audio=@('.mp3','.wav','.flac','.ogg','.opus','.aac','.m4a','.wma','.aiff');Documents=@('.pdf','.txt','.md','.doc','.docx','.xls','.xlsx','.ppt','.pptx','.odt','.ods','.rtf','.csv','.json','.xml','.html','.srt','.vtt');Archives=@('.zip','.7z','.rar','.tar','.gz','.bz2','.xz','.zst')}
 Invoke-LocalBatch $files {'organized-types'} {
  param($source,$result,$file,$all)
  $rows=@(foreach($entry in $all){
   $category='Other';foreach($key in $types.Keys){if($entry.Extension.ToLowerInvariant() -in $types[$key]){$category=$key;break}}
   $relative=Get-RelativeName $script:InputDir $entry.FullName;$targetRelative=$category+'\'+$relative;$target=Join-Path $result $targetRelative
   Ensure-Directory ([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($entry.FullName,$target,$false)
   $hash=(Get-FileHash -LiteralPath $entry.FullName).Hash;if((Get-FileHash -LiteralPath $target).Hash -ne $hash){throw 'Copy checksum mismatch.'}
   [pscustomobject]@{Source=$relative;Category=$category;Copy=$targetRelative;Bytes=$entry.Length;SHA256=$hash}
  })
  $rows|Export-Csv -LiteralPath (Join-Path $result 'files.csv') -NoTypeInformation -Encoding UTF8
  $rows|Group-Object Category|Select-Object @{n='Category';e={$_.Name}},Count|Export-Csv -LiteralPath (Join-Path $result 'categories.csv') -NoTypeInformation -Encoding UTF8
 } -Aggregate -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
