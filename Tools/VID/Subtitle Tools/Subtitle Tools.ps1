param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
function Read-Subtitle([string]$Path,[bool]$VTT){
 $text=[IO.File]::ReadAllText($Path,(New-Object Text.UTF8Encoding($false,$true))).TrimStart([char]0xFEFF).Replace("`r`n","`n").Replace("`r","`n")
 if($text.Contains([char]0)){throw 'Binary/NUL text refused.'}
 if($VTT){if($text -notmatch '^WEBVTT(?:[^\n]*)\n') {throw 'Missing WEBVTT header.'};$text=$text.Substring($text.IndexOf("`n")+1).TrimStart("`n")}
 $cues=New-Object 'Collections.Generic.List[object]';$issues=New-Object 'Collections.Generic.List[object]';$sequence=0;$lastEnd=0L
 foreach($block in ([regex]::Split($text.Trim(),'\n[ \t]*\n'))){
  $sequence++;$lines=@($block -split "`n");$timeIndex=if($lines.Count -gt 0 -and $lines[0].Contains('-->')){0}else{1}
  if($VTT -and $lines[0] -match '^(NOTE|STYLE|REGION)( |$)'){throw 'VTT NOTE/STYLE/REGION blocks require manual conversion; not silently discarded.'}
  $number=0;if(-not $VTT -and ($timeIndex -ne 1 -or -not [int]::TryParse($lines[0],[ref]$number))){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='Invalid index';Fatal=$true});continue}
  if($timeIndex -ge $lines.Count -or $lines[$timeIndex] -notmatch '^(?<a>(?:\d{2,}:)?\d{2}:\d{2}[,.]\d{3})\s+-->\s+(?<b>(?:\d{2,}:)?\d{2}:\d{2}[,.]\d{3})(?<settings>.*)$'){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='Malformed timing line';Fatal=$true});continue}
  $a=Convert-SubtitleTime $Matches.a;$b=Convert-SubtitleTime $Matches.b;$settings=$Matches.settings
  if($settings.Trim()){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='Cue settings cannot be preserved by basic conversion';Fatal=$true})}
  if(-not $VTT -and $number -ne $sequence){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='Nonsequential index';Fatal=$false})}
  if($b -le $a){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='End must follow start';Fatal=$true})}
  if($sequence -gt 1 -and $a -lt $lastEnd){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='Overlapping cues';Fatal=$false})}
  $lastEnd=$b
  $body=if($lines.Count -gt $timeIndex+1){($lines[($timeIndex+1)..($lines.Count-1)] -join "`r`n")}else{''}
  if(-not $body){$issues.Add([pscustomobject]@{Cue=$sequence;Kind='Empty cue text';Fatal=$true})}
  $cues.Add([pscustomobject]@{Index=$(if($VTT){$sequence}else{$number});Start=$a;End=$b;Text=$body})
 }
 if(-not $cues.Count -and -not $issues.Count){throw 'No subtitle cues.'}
 [pscustomobject]@{Cues=$cues;Issues=$issues}
}
function Convert-SubtitleTime([string]$Value){
 $parts=$Value.Replace(',','.').Split(':');$h=0L;$m=0L;$s=0.0
 if($parts.Count -eq 3){$h=[long]$parts[0];$m=[long]$parts[1];$s=[double]::Parse($parts[2],[Globalization.CultureInfo]::InvariantCulture)}else{$m=[long]$parts[0];$s=[double]::Parse($parts[1],[Globalization.CultureInfo]::InvariantCulture)}
 if($m -gt 59 -or $s -ge 60){throw 'Minutes/seconds outside 0-59.'}
 [long][Math]::Round(($h*3600+$m*60+$s)*1000)
}
function Format-SubtitleTime([long]$Milliseconds,[bool]$VTT){
 $ms=$Milliseconds%1000;$seconds=[long][Math]::Floor($Milliseconds/1000);$s=$seconds%60;$minutes=[long][Math]::Floor($seconds/60);$m=$minutes%60;$h=[long][Math]::Floor($minutes/60)
 ('{0:D2}:{1:D2}:{2:D2}{3}{4:D3}' -f $h,$m,$s,$(if($VTT){'.'}else{','}),$ms)
}
try {
 Show-LocalTool 'Subtitle Tools' $PSScriptRoot $Mode '' 'Validate SRT (default), shift timings, or convert basic SRT/WebVTT. UTF-8/UTF-16 BOM supported. Originals unchanged.'
 $choice=Read-LocalChoice $Mode @('Validate SRT; report only','Shift SRT times','SRT to WebVTT','WebVTT to SRT')
 $offset=0L
 if($choice -eq 2){$value=Read-Host 'Signed seconds (-86400 to +86400)';if($value -notmatch '^[+-]?\d{1,5}(\.\d{1,3})?$'){throw 'Invalid signed seconds.'};$n=[double]::Parse($value,[Globalization.CultureInfo]::InvariantCulture);if([Math]::Abs($n) -gt 86400){throw 'Offset exceeds one day.'};$offset=[long][Math]::Round($n*1000)}
 $files=@(Get-SafeFiles $script:InputDir @($(if($choice -eq 4){'.vtt'}else{'.srt'})))
 Invoke-LocalBatch $files {param($f)$f.Name+'.subtitles'} {
  param($source,$result)
  $data=Read-Subtitle $source ($choice -eq 4)
  if($data.Issues.Count){$data.Issues|Export-Csv -LiteralPath (Join-Path $result 'issues.csv') -NoTypeInformation -Encoding UTF8}
  @{Cues=$data.Cues.Count;Issues=$data.Issues.Count;Fatal=@($data.Issues|Where-Object Fatal).Count}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $result 'summary.json') -Encoding UTF8
  if($choice -eq 1){Write-Host ('Validation issues: '+$data.Issues.Count);return}
  if(@($data.Issues|Where-Object Fatal).Count){throw 'Invalid subtitle; use Validate and read issues.csv before conversion/shifting.'}
  $vtt=$choice -eq 3;$output=New-Object 'Collections.Generic.List[string]';if($vtt){$output.Add("WEBVTT`r`n")}
  foreach($cue in $data.Cues){
   $start=$cue.Start;$end=$cue.End
   if($choice -eq 2){$start=[Math]::Max([long]0,([long]$start+$offset));$end=[Math]::Max([long]0,([long]$end+$offset));if($end -le $start){throw 'Shift would erase a cue before time zero; use a smaller negative offset. No output published.'}}
   $output.Add($cue.Index.ToString());$output.Add((Format-SubtitleTime $start $vtt)+' --> '+(Format-SubtitleTime $end $vtt));$output.Add($cue.Text);$output.Add('')
  }
  $name=if($vtt){'converted.vtt'}elseif($choice -eq 4){'converted.srt'}else{'shifted.srt'}
  [IO.File]::WriteAllText((Join-Path $result $name),($output -join "`r`n"),(New-Object Text.UTF8Encoding($false)))
 } -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
