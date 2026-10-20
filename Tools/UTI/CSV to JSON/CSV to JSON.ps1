param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {

Show-LocalTool 'CSV to JSON' $PSScriptRoot $Mode '' 'CSV to JSON: use the local Input folder; originals and previous outputs are preserved. Read the MD for options and limits.'
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
$choice=Read-LocalChoice $Mode @('Comma CSV to JSON (all values stay strings)','Semicolon CSV to JSON','Flat string-only JSON array to comma CSV')
$ext=if($choice -eq 3){@('.json')}else{@('.csv')}
$files=@(Get-SafeFiles $script:InputDir $ext)
Invoke-LocalBatch $files {param($f) $f.Name+$(if($choice -eq 3){'.csv'}else{'.json'})} {
 param($source,$result)
 $doc=Read-Text $source
 if($choice -ne 3){
  Add-Type -AssemblyName Microsoft.VisualBasic
  $reader=New-Object IO.StringReader($doc.Text);$parser=New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($reader)
  try{
   $parser.SetDelimiters($(if($choice -eq 2){';'}else{','}));$parser.HasFieldsEnclosedInQuotes=$true;$parser.TrimWhiteSpace=$false
   if($parser.EndOfData){throw 'CSV header is missing.'};$headers=$parser.ReadFields()
   $keys=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
   foreach($h in $headers){if(-not $h -or -not $keys.Add($h)){throw 'CSV headers must be nonempty and unique, ignoring case.'}}
   if($headers.Count -gt 1000){throw 'At most 1000 columns.'}
   $rows=New-Object 'Collections.Generic.List[object]'
   while(-not $parser.EndOfData){
    $values=$parser.ReadFields();if($values.Count -ne $headers.Count){throw 'CSV row has a different field count.'}
    $row=[ordered]@{};for($i=0;$i -lt $headers.Count;$i++){$row.Add($headers[$i],[string]$values[$i])};$rows.Add([pscustomobject]$row)
    if($rows.Count -gt 100000){throw 'At most 100000 rows.'}
   }
   ConvertTo-Json -InputObject @($rows.ToArray()) -Depth 5|Set-Content -LiteralPath $result -Encoding UTF8
  }finally{$parser.Dispose();$reader.Dispose()}
 }else{
  if((Get-Item -LiteralPath $source).Length -gt 8MB){throw 'JSON reverse limit: 8MB.'}
  # Restricted grammar avoids numeric conversion and rejects ambiguous nested data.
  $text=$doc.Text;$script:Tokens=New-Object 'Collections.Generic.List[string]';$position=0
  $regex=New-Object Text.RegularExpressions.Regex('\G[ \t\r\n]*("(?:[^"\\\x00-\x1f]|\\["\\/bfnrt]|\\u[0-9A-Fa-f]{4})*"|[\[\]{},:])',[Text.RegularExpressions.RegexOptions]::None,[TimeSpan]::FromSeconds(2))
  while($position -lt $text.Length){$m=$regex.Match($text,$position);if(-not $m.Success -or $m.Index -ne $position){if($text.Substring($position) -match '^[ \t\r\n]*$'){break};throw 'JSON reverse requires strings only; numbers, null and other values are refused.'};$script:Tokens.Add($m.Groups[1].Value);$position+=$m.Length;if($script:Tokens.Count -gt 500000){throw 'JSON token limit exceeded.'}}
  $script:Index=0
  function Peek {if($script:Index -lt $script:Tokens.Count){$script:Tokens[$script:Index]}else{''}}
  function Take([string]$Expected){if((Peek) -cne $Expected){throw ('Expected JSON token '+$Expected)};$script:Index++}
  function Read-String {if((Peek) -notmatch '^"'){throw 'A JSON string is required.'};$value=$script:Tokens[$script:Index]|ConvertFrom-Json;$script:Index++;[string]$value}
  Take '[';$rows=New-Object 'Collections.Generic.List[object]';$headers=@()
  while((Peek) -ne ']'){
   Take '{';$row=[ordered]@{}
   while((Peek) -ne '}'){
    $key=Read-String;if(-not $key -or $row.Contains($key)){throw 'Empty/duplicate JSON keys refused.'}
    Take ':';$value=Read-String;$row.Add($key,$value)
    if((Peek) -ne ','){break};Take ',';if((Peek) -eq '}'){throw 'Trailing comma refused.'}
   }
   Take '}'
   if(-not $row.Count){throw 'JSON objects require at least one named string field.'}
   if(-not $headers.Count){$headers=@($row.Keys)}
   if($row.Count -ne $headers.Count -or @($row.Keys|Where-Object {$_ -cnotin $headers}).Count){throw 'All objects must have the same keys.'}
   $ordered=[ordered]@{};foreach($key in $headers){$ordered.Add($key,$row[$key])};$rows.Add([pscustomobject]$ordered)
   if((Peek) -ne ','){break};Take ',';if((Peek) -eq ']'){throw 'Trailing comma refused.'}
  }
  Take ']';if($script:Index -ne $script:Tokens.Count -or -not $rows.Count){throw 'Unexpected JSON content or empty array with no CSV header.'}
  $rows.ToArray()|Export-Csv -LiteralPath $result -NoTypeInformation -Encoding UTF8
 }
}
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
