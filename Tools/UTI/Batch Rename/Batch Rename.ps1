param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Batch Rename' $PSScriptRoot $Mode '' 'Batch Rename: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

$choice=Read-LocalChoice $Mode @('Copy with prefix copy_','Copy with suffix _copy','Copy with literal replacement','Copy with item_0001 numbering','RENAME ORIGINALS with preview and backup')
$inPlace=$choice -eq 5;$pattern=$choice
if($inPlace){$pattern=Read-LocalChoice 'Interactive' @('Prefix','Suffix','Literal replacement','Numbering')}
$prefix='copy_';$suffix='_copy';$find='';$replace=''
if($Mode -ne 'Defaults' -and $pattern -eq 1){$p=Read-Host 'Prefix [copy_]';if($p){$prefix=$p}}
if($Mode -ne 'Defaults' -and $pattern -eq 2){$p=Read-Host 'Suffix [_copy]';if($p){$suffix=$p}}
if($pattern -eq 3){$find=Read-Host 'Literal text to replace in basename';$replace=Read-Host 'Replacement (may be empty)';if(-not $find){throw 'Search text cannot be empty.'}}
$files=@(Get-SafeFiles $script:InputDir $null)
if(-not $files.Count){Write-Host '[INFO] No supported input files.';exit 0}
if($files.Count -gt 10000){throw 'At most 10000 files.'}
$destination=Join-Path $script:OutputDir 'rename-plan'
if(Test-Path -LiteralPath $destination){Write-Host '[SKIPPED] rename-plan exists.';exit 0}
if($destination.Length -gt 200){throw 'Use a shorter project path.'}
$names=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$sourceNames=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($f in $files){[void]$sourceNames.Add($f.Name)}
$i=0
$plan=@(foreach($f in $files){
 $i++;$name=switch($pattern){1{$prefix+$f.BaseName+$f.Extension};2{$f.BaseName+$suffix+$f.Extension};3{$f.BaseName.Replace($find,$replace)+$f.Extension};4{'item_'+('{0:D4}' -f $i)+$f.Extension}}
 if(-not $name -or $name -ne [IO.Path]::GetFileName($name) -or $name -match '[\x00-\x1f<>:"/\\|?*]|[. ]$|^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)' -or $name.Length -gt 255 -or -not $names.Add($name)){throw ('Invalid or conflicting target name: '+$name)}
 if((Join-Path $script:InputDir $name).Length -gt 240 -or (Join-Path $destination ('Originals\'+$f.Name)).Length -gt 240 -or (Join-Path $destination ('Copies\'+$name)).Length -gt 240){throw 'Target path exceeds 240 characters.'}
 if($inPlace -and (Test-Path -LiteralPath (Join-Path $script:InputDir $name)) -and -not $sourceNames.Contains($name)){throw 'A target already exists outside the selected files.'}
 [pscustomobject]@{Original=$f.Name;NewName=$name;SHA256=(Get-FileHash -LiteralPath $f.FullName).Hash}
})
$plan|Select-Object Original,NewName|Format-Table -AutoSize|Out-Host
$confirmed=$false;if($inPlace){$confirmed=(Read-Host 'Type RENAME ORIGINALS to apply; originals are backed up first') -ceq 'RENAME ORIGINALS'}
Test-FreeSpace $script:OutputDir ([long]($files|Measure-Object Length -Sum).Sum+16MB)
$work=New-WorkDirectory $script:OutputDir
try{
 $result=Join-Path $work 'plan';Ensure-Directory $result
 $plan|Export-Csv -LiteralPath (Join-Path $result 'preview.csv') -NoTypeInformation -Encoding UTF8
 $folder=if($inPlace){'Originals'}else{'Copies'}
 if(-not $inPlace -or $confirmed){
  Ensure-Directory (Join-Path $result $folder)
  foreach($row in $plan){$target=Join-Path (Join-Path $result $folder) $(if($inPlace){$row.Original}else{$row.NewName});[IO.File]::Copy((Join-Path $script:InputDir $row.Original),$target,$false);if((Get-FileHash -LiteralPath $target).Hash -ne $row.SHA256){throw 'Backup/copy hash mismatch.'}}
 }
 [IO.File]::WriteAllText((Join-Path $result 'status.txt'),$(if($inPlace -and -not $confirmed){'Rename declined; preview only.'}elseif($inPlace){'Backups verified; rename pending.'}else{'Copies produced; originals unchanged.'}))
 [IO.Directory]::Move($result,$destination)
}finally{Remove-WorkDirectory $work $script:OutputDir}
if($inPlace -and $confirmed){
 $staging=New-WorkDirectory $script:InputDir;$moves=@();$rollbackFailed=$false
 try{
  $i=0
  foreach($row in $plan){$i++;$source=Join-Path $script:InputDir $row.Original;$temp=Join-Path $staging ($i.ToString()+'.tmp');$target=Join-Path $script:InputDir $row.NewName
   if((Get-FileHash -LiteralPath $source).Hash -ne $row.SHA256){throw 'Source changed after preview.'}
   [IO.File]::Move($source,$temp);$moves+=[pscustomobject]@{Source=$source;Temp=$temp;Target=$target;Published=$false}
  }
  foreach($m in $moves){[IO.File]::Move($m.Temp,$m.Target);$m.Published=$true}
  [IO.File]::WriteAllText((Join-Path $destination 'status.txt'),'Originals renamed; full byte-verified backups are in Originals.')
 }catch{
  try{foreach($m in $moves){if($m.Published){[IO.File]::Move($m.Target,$m.Temp)}};foreach($m in $moves){if([IO.File]::Exists($m.Temp)){[IO.File]::Move($m.Temp,$m.Source)}}}catch{$rollbackFailed=$true}
  [IO.File]::WriteAllText((Join-Path $destination 'status.txt'),('Rename failed. RollbackIncomplete='+$rollbackFailed+'. Recovery backups: Originals; temporary path: '+$staging))
  throw
 }finally{if(-not @(Get-SafeFiles $staging $null -Recurse).Count){Remove-WorkDirectory $staging $script:InputDir}else{Write-Host ('[RECOVERY] Files retained in '+$staging)}}
}
Write-Host '[SUCCESS] rename-plan';Write-Host ('Total: '+$plan.Count+' Successful: '+$plan.Count+' Failed: 0 Skipped: 0')
exit 0
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
