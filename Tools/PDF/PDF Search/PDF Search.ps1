param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 Show-LocalTool 'PDF Search' $PSScriptRoot $Mode 'ghostscript' 'Find a literal phrase in each PDF page; extraction order is not guaranteed. Default phrase: test.'
 $script:PDFEngine=$script:Engine
 $choice=Read-LocalChoice $Mode @('Search test (case insensitive)','Custom literal phrase (case insensitive)','Custom literal phrase (case sensitive)')
 $phrase='test';if($choice -ne 1){$phrase=Read-Host 'Literal phrase'}
 if([string]::IsNullOrWhiteSpace($phrase) -or $phrase.Length -gt 500){throw 'Enter a nonempty phrase up to 500 characters.'}
 $comparison=if($choice -eq 3){[StringComparison]::Ordinal}else{[StringComparison]::OrdinalIgnoreCase}
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
 Invoke-LocalBatch $files {'search-report'} {
  param($source,$result,$file,$all)
  $matches=New-Object 'Collections.Generic.List[object]';$status=New-Object 'Collections.Generic.List[object]';$i=0
  foreach($pdf in $all){
   $i++;$alias='input'+$i+'.pdf';[IO.File]::Copy($pdf.FullName,(Join-Path $script:NativeWorkingDirectory $alias),$false)
   $count=Get-PDFCount $alias
   for($page=1;$page -le $count;$page++){
    $text=Get-PDFText $alias $page
    $status.Add([pscustomobject]@{File=$pdf.Name;Page=$page;Status=$(if($text.Trim()){'Text extracted; reading order must be checked'}else{'No extractable text; use PDF OCR'})})
    # Match within one extracted line only; never join unrelated columns/lines.
    foreach($line in ($text -split '\r?\n')){if($line.IndexOf($phrase,$comparison) -ge 0){$matches.Add([pscustomobject]@{File=$pdf.Name;Page=$page;Phrase=$phrase;ExtractedLine=$line.Trim();Caution='Verify this occurrence visually; PDF text order may differ from reading order.'})}}
   }
  }
  if($matches.Count){$matches|Export-Csv -LiteralPath (Join-Path $result 'matches.csv') -NoTypeInformation -Encoding UTF8}else{[IO.File]::WriteAllText((Join-Path $result 'matches.csv'),'"File","Page","Phrase","ExtractedLine","Caution"', (New-Object Text.UTF8Encoding($true)))}
  $status|Export-Csv -LiteralPath (Join-Path $result 'pages.csv') -NoTypeInformation -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $result 'summary.txt'),('Matching lines: '+$matches.Count+'. Phrase: '+$phrase+'. No matches does not prove absence: scanned pages, RTL layout, ligatures, line breaks or PDF encoding can prevent extraction.'))
 } -Aggregate -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
