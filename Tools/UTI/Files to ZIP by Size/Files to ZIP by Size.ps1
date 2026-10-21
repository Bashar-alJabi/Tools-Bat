param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Archives.ps1')
try {
 Show-LocalTool 'Files to ZIP by Size' $PSScriptRoot $Mode '' 'Create independent ZIP archives within an actual byte limit; verify extracted hashes. No file splitting.'
 $choice=Read-LocalChoice $Mode @('100 MiB per ZIP','Custom size in MiB (1-4096)')
 $mb=100;if($choice -eq 2){$mb=Read-LocalNumber 'Maximum MiB, integer 1-4096' 1 4096;if($mb -notmatch '^\d+$'){throw 'Integer size required.'}}
 $limit=[long]$mb*1MB
 $files=@(Get-SafeFiles $script:InputDir $null -Recurse)
 if($files.Count -gt 5000){throw 'At most 5000 files per run; use smaller batches.'}
 foreach($f in $files){if($f.Length -ge $limit){throw ('File too large for a complete ZIP within this limit (including headers): '+$f.Name+'. Increase the limit; no raw splitting is performed.')}}
 Invoke-LocalBatch $files {'zip-parts'} {
  param($source,$result,$file,$all)
  $parts=New-Object 'Collections.Generic.List[object]';$group=@();$previous=$null;$trial=0;$part=1
  foreach($entry in $all){
   $trial++;$candidate=Join-Path $script:NativeWorkingDirectory ('trial'+$trial+'.zip');$proposed=@($group)+@($entry)
   Zip-Create $proposed $script:InputDir $candidate
   if((Get-Item -LiteralPath $candidate).Length -gt $limit){
    [IO.File]::Delete($candidate) # Own private trial only; no user file is deleted.
    if(-not $group.Count){throw ('A complete archive for '+$entry.Name+' exceeds the limit including ZIP metadata.')}
    $name='part-'+('{0:D3}' -f $part)+'.zip';[IO.File]::Move($previous,(Join-Path $result $name));$parts.Add([pscustomobject]@{Name=$name;Files=@($group)})
    $part++;$group=@($entry);$trial++;$previous=Join-Path $script:NativeWorkingDirectory ('trial'+$trial+'.zip');Zip-Create $group $script:InputDir $previous
    if((Get-Item -LiteralPath $previous).Length -gt $limit){throw ('A complete archive for '+$entry.Name+' exceeds the limit including ZIP metadata.')}
   }else{if($previous){[IO.File]::Delete($previous)};$group=$proposed;$previous=$candidate}
  }
  if($group.Count){$name='part-'+('{0:D3}' -f $part)+'.zip';[IO.File]::Move($previous,(Join-Path $result $name));$parts.Add([pscustomobject]@{Name=$name;Files=@($group)})}
  $rows=@(foreach($partInfo in $parts){
   $zip=Join-Path $result $partInfo.Name;if((Get-Item -LiteralPath $zip).Length -gt $limit){throw 'Archive exceeds actual byte limit.'}
   $verify=Join-Path $script:NativeWorkingDirectory ('verify-'+$partInfo.Name);Zip-Extract $zip $verify
   foreach($f in $partInfo.Files){$relative=Get-RelativeName $script:InputDir $f.FullName;$hash=(Get-FileHash -LiteralPath $f.FullName).Hash
    if((Get-FileHash -LiteralPath (Join-Path $verify $relative)).Hash -ne $hash){throw 'Extracted ZIP content hash mismatch.'}
    [pscustomobject]@{Archive=$partInfo.Name;ArchiveBytes=(Get-Item -LiteralPath $zip).Length;File=$relative;Bytes=$f.Length;SHA256=$hash}
   }
  })
  $rows|Export-Csv -LiteralPath (Join-Path $result 'index.csv') -NoTypeInformation -Encoding UTF8
 } -Aggregate -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
