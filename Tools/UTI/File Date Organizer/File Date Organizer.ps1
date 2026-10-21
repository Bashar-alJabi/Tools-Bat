param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
 Show-LocalTool 'File Date Organizer' $PSScriptRoot $Mode '' 'Copy Input recursively into year/month folders using modification, creation, or EXIF DateTimeOriginal with an explicit fallback policy.'
 $choice=Read-LocalChoice $Mode @('Modification time','Creation time','EXIF shooting time; fallback to modification','EXIF shooting time only; report files without EXIF as skipped')
 if($choice -ge 3){Add-Type -AssemblyName System.Drawing}
 $files=@(Get-SafeFiles $script:InputDir $null -Recurse)
 Invoke-LocalBatch $files {'organized-dates'} {
  param($source,$result,$file,$all)
  $rows=@(foreach($entry in $all){
   $date=$entry.LastWriteTime;$used='Modification';$relative=Get-RelativeName $script:InputDir $entry.FullName;$copy='';$status='Copied'
   if($choice -eq 2){$date=$entry.CreationTime;$used='Creation'}
   if($choice -ge 3){
    $found=$false;$image=$null
    if($entry.Extension.ToLowerInvariant() -in @('.jpg','.jpeg','.tif','.tiff')){
     try{$image=[Drawing.Image]::FromFile($entry.FullName);$raw=[Text.Encoding]::ASCII.GetString($image.GetPropertyItem(0x9003).Value).Trim([char]0);$parsed=[datetime]::MinValue
      if([datetime]::TryParseExact($raw,'yyyy:MM:dd HH:mm:ss',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$parsed)){$date=$parsed;$used='EXIF DateTimeOriginal (no timezone assumed)';$found=$true}
     }catch{}finally{if($image){$image.Dispose()}}
    }
    if(-not $found){$used='Modification fallback (no readable EXIF)';if($choice -eq 4){$used='No readable EXIF';$status='Skipped'}}
   }
   $hash=(Get-FileHash -LiteralPath $entry.FullName).Hash
   if($status -eq 'Copied'){
    $copy=$date.ToString('yyyy',[Globalization.CultureInfo]::InvariantCulture)+'\'+$date.ToString('MM',[Globalization.CultureInfo]::InvariantCulture)+'\'+$relative;$target=Join-Path $result $copy
    Ensure-Directory ([IO.Path]::GetDirectoryName($target));[IO.File]::Copy($entry.FullName,$target,$false)
    if((Get-FileHash -LiteralPath $target).Hash -ne $hash){throw 'Copy checksum mismatch.'}
   }
   [pscustomobject]@{Source=$relative;Status=$status;DateSource=$used;Date=$date.ToString('o');Copy=$copy;SHA256=$hash}
  })
  $rows|Export-Csv -LiteralPath (Join-Path $result 'dates.csv') -NoTypeInformation -Encoding UTF8
  Write-Host ('Files copied: '+@($rows|Where-Object Status -eq 'Copied').Count+'; skipped (missing EXIF): '+@($rows|Where-Object Status -eq 'Skipped').Count)
 } -Aggregate -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
