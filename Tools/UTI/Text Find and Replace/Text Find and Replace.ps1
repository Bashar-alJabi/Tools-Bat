param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'Text Find and Replace' $PSScriptRoot $Mode '' 'Text Find and Replace: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
$imageExt=@('.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff','.avif')
$videoExt=@('.mp4','.mkv','.mov','.avi','.m4v','.webm')
$audioExt=@('.mp3','.wav','.m4a','.aac','.flac','.ogg','.opus','.wma')

function Read-Text([string]$Path){
 $bytes=[IO.File]::ReadAllBytes($Path);$offset=0
 if($bytes.Length -gt 32MB){throw 'Text limit: 32MB.'}
 if($bytes.Length -ge 4 -and (($bytes[0] -eq 255 -and $bytes[1] -eq 254 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0) -or ($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 254 -and $bytes[3] -eq 255))){throw 'UTF-32 is unsupported.'}
 if($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254){$enc=New-Object Text.UnicodeEncoding($false,$true,$true);$offset=2;$label='UTF-16LE BOM'}
 elseif($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255){$enc=New-Object Text.UnicodeEncoding($true,$true,$true);$offset=2;$label='UTF-16BE BOM'}
 else{$bom=$bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191;$enc=New-Object Text.UTF8Encoding($bom,$true);if($bom){$offset=3};$label=if($bom){'UTF-8 BOM'}else{'UTF-8'}}
 $text=$enc.GetString($bytes,$offset,($bytes.Length-$offset))
 if($text -match '[\x00-\x08\x0b\x0c\x0e-\x1f]'){throw 'Binary/control characters refused; convert the source explicitly to supported text first.'}
 [pscustomobject]@{Text=$text;Encoding=$enc;Label=$label}
}
$choice=Read-LocalChoice $Mode @('Preview TODO -> DONE only','Custom literal replacement; preview before WRITE confirmation')
$find='TODO';$replace='DONE'
if($choice -eq 2){$find=Read-Host 'Find literal text (case sensitive)';$replace=Read-Host 'Replacement text (may be empty)'}
if(-not $find -or $find.Length -gt 1024 -or $replace.Length -gt 4096){throw 'Find must be 1-1024 characters; replacement at most 4096.'}
$files=@(Get-SafeFiles $script:InputDir @('.txt','.md','.csv','.json','.xml','.ini','.log','.srt','.vtt','.yaml','.yml'))
Invoke-LocalBatch $files {'replacements'} {
 param($source,$result,$file,$all)
 $rows=@();$documents=@{}
 foreach($f in $all){$d=Read-Text $f.FullName;$documents[$f.Name]=$d;$count=[regex]::Matches($d.Text,[regex]::Escape($find)).Count;$rows+=[pscustomobject]@{File=$f.Name;Matches=$count;Encoding=$d.Label;OriginalCharacters=$d.Text.Length;ResultCharacters=$d.Text.Replace($find,$replace).Length}}
 $rows|Select-Object File,Matches,Encoding|Format-Table -AutoSize|Out-Host
 $rows|Export-Csv -LiteralPath (Join-Path $result 'preview.csv') -NoTypeInformation -Encoding UTF8
 $apply=$false;if($choice -eq 2){$apply=(Read-Host 'Type WRITE to create changed copies; originals stay untouched') -ceq 'WRITE'}
 if($apply){
  $copies=Join-Path $result 'Copies';Ensure-Directory $copies
  foreach($row in $rows){if($row.Matches -gt 0){$doc=$documents[$row.File];[IO.File]::WriteAllText((Join-Path $copies $row.File),$doc.Text.Replace($find,$replace),$doc.Encoding)}}
 }else{Write-Host '[INFO] Preview only; no changed copies produced.'}
} -Aggregate -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
