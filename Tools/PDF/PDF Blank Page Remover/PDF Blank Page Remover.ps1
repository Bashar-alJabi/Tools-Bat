param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\PDF.ps1')
try {
 if($Mode -ne 'Help'){$script:Magick=Require-Dependency 'magick'}
 Show-LocalTool 'PDF Blank Page Remover' $PSScriptRoot $Mode 'ghostscript' 'Conservative full-page scan: preview/report first; only confirmed blank pages can be removed from a new copy.'
 $script:PDFEngine=$script:Engine
 $choice=Read-LocalChoice $Mode @('Preview and report only','Preview, exclusions and explicit REMOVE confirmation')
 $files=@(Get-SafeFiles $script:InputDir @('.pdf'))
 Invoke-LocalBatch $files {param($f)$f.Name+'.blank-review'} {
  param($source,$result)
  $count=Get-PDFCount 'source.pdf';$candidates=New-Object 'Collections.Generic.List[int]'
  $rows=@(for($p=1;$p -le $count;$p++){
   Render-PDFPage 'source.pdf' $p ('result/page-'+$p+'.png') 150
   $minimum=(Invoke-Checked $script:Magick @(('result/page-'+$p+'.png'),'-alpha','off','-colorspace','Gray','-format','%[fx:minima]','info:')).Trim()
   $min=[double]::Parse($minimum,[Globalization.CultureInfo]::InvariantCulture);$text=Get-PDFText 'source.pdf' $p
   # No area-fraction threshold: a single dark or faint mark keeps the page.
   $blank=$min -ge 0.9999 -and -not $text.Trim();if($blank){$candidates.Add($p)}
   [pscustomobject]@{Page=$p;MinBrightness=$min;HasText=[bool]$text.Trim();Candidate=$blank;Decision=$(if($blank){'Visually white at 150 DPI; needs confirmation'}else{'Keep: nonwhite, text, or uncertain'})}
  })
  $rows|Export-Csv -LiteralPath (Join-Path $result 'preview.csv') -NoTypeInformation -Encoding UTF8
  Write-Host ('Blank candidates: '+($candidates -join ', '));Write-Host ('Preview images: '+$result)
  $remove=@()
  if($choice -eq 2 -and $candidates.Count){
   $excluded=Read-Host 'Pages to KEEP (list/ranges), or Enter for none';$keep=@();if($excluded){$keep=Get-PDFSelection $excluded $count}
   $remove=@($candidates|Where-Object{$_ -notin $keep});Write-Host ('Proposed removal: '+($remove -join ', '))
   if((Read-Host 'Inspect previews before continuing. Type REMOVE to create the reduced copy') -cne 'REMOVE'){$remove=@()}
  }
  if($remove.Count){
   if($remove.Count -eq $count){throw 'Refusing to remove every page.'}
   $parts=@();for($p=1;$p -le $count;$p++){if($p -notin $remove){$name='keep'+$p+'.pdf';Export-PDFPage 'source.pdf' $p $name;$parts+=$name}}
   Join-PDFPages $parts 'result/cleaned.pdf'
  }
  @{OriginalPages=$count;Candidates=@($candidates);Removed=@($remove);Conservative='Only completely white raster pages without extracted text are candidates. Noise may prevent removal; subpixel marks may escape detection. Review every candidate.'}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $result 'decision.json') -Encoding UTF8
 } -DirectoryResult
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
