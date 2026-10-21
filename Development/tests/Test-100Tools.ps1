param([ValidateSet('1','2','All')][string]$Phase='1',[string]$Only)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\PDF.ps1')
$root=$script:ProjectRoot
# Reuse only the existing test process/hash helpers; do not run its test suite here.
$tokens=$null;$parse=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Test-Expansion.ps1'),[ref]$tokens,[ref]$parse)
foreach($name in @('Assert','Run-Bat','HashTree','Probe','Image-Info','PDF-Count','Copy-Fixture')){
 $definition=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
 . ([scriptblock]::Create($definition.Extent.Text))
}
$work=Join-Path $PSScriptRoot ('_work\hundred-'+[guid]::NewGuid().ToString('N').Substring(0,8));Ensure-Directory $work
$project=Join-Path $work 'مشروع عربي & ! %X% [1]';Ensure-Directory (Join-Path $project 'System')
Copy-Item -LiteralPath (Join-Path $root 'System\Shared') -Destination (Join-Path $project 'System\Shared') -Recurse
Ensure-Directory (Join-Path $project 'System\Bin')
foreach($name in @('qpdf','Tesseract')){if(Test-Path -LiteralPath (Join-Path $root ('System\Bin\'+$name))){Copy-Item -LiteralPath (Join-Path $root ('System\Bin\'+$name)) -Destination (Join-Path $project ('System\Bin\'+$name)) -Recurse}}
$fixtures=Join-Path $work 'f';Ensure-Directory $fixtures;$script:NativeWorkingDirectory=$fixtures
$results=New-Object 'Collections.Generic.List[object]'
function Record([string]$Name,[bool]$Passed,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$Passed;Detail=$Detail.Replace($root,'<PROJECT_ROOT>')});Write-Host ($(if($Passed){'PASS '}else{'FAIL '})+$Name+': '+$Detail)}
$gs=Require-Dependency 'ghostscript';$script:PDFEngine=$gs;$magick=Require-Dependency 'magick';$ff=Require-Dependency 'ffmpeg';$probe=Require-Dependency 'ffprobe';$qpdf=Require-Dependency 'qpdf'
$password=[guid]::NewGuid().ToString('N');$wrong=[guid]::NewGuid().ToString('N')
[void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=pages.pdf','-c','<</PageSize [300 400]>> setpagedevice /Helvetica findfont 20 scalefont setfont 50 300 moveto (test PAGE ONE) show showpage <</PageSize [400 300]>> setpagedevice 50 200 moveto (PAGE TWO) show showpage'))
[void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=blank.pdf','-c','<</PageSize [300 400]>> setpagedevice showpage 0.98 setgray 30 300 moveto /Helvetica findfont 12 scalefont setfont (FAINT) show showpage 0 setgray 299 399 0.5 0.5 rectfill showpage 50 50 2 2 rectfill showpage'))
$null=Invoke-QPDFJob $qpdf @{inputFile='pages.pdf';outputFile='protected.pdf';encrypt=@{userPassword=$password;ownerPassword=[guid]::NewGuid().ToString('N');'256bit'=@{}}}
[void](Invoke-Checked $magick @('-size','100x60','xc:red','image.png'))
$bytes=New-Object byte[] 700000;$rng=[Security.Cryptography.RandomNumberGenerator]::Create();$rng.GetBytes($bytes);$rng.Dispose();[IO.File]::WriteAllBytes((Join-Path $fixtures 'random.bin'),$bytes)
[IO.File]::WriteAllText((Join-Path $fixtures 'text.txt'),'test عربي',(New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $fixtures 'text.srt'),"1`r`n00:00:01,000 --> 00:00:02,000`r`nمرحبا TEST`r`n`r`n2`r`n00:00:03,000 --> 00:00:04,000`r`nالعالم`r`n",(New-Object Text.UTF8Encoding($false)))
[void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-f','lavfi','-i','testsrc2=s=160x90:r=10:d=4','-c:v','libx264','-pix_fmt','yuv420p','video.mp4'))
$catalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
$catalog=@($catalog|Where-Object{$_.PSObject.Properties['Expansion'] -and $_.Expansion -like '2026-10-21-*' -and ($Phase -eq 'All' -or $_.Expansion -eq ('2026-10-21-'+$Phase)) -and (-not $Only -or $_.Name -eq $Only)})
foreach($tool in $catalog){
 $bat=Join-Path $project $tool.Path;$dir=Split-Path $bat;Ensure-Directory $dir
 foreach($ext in @('.bat','.ps1','.md')){Copy-Item -LiteralPath ([IO.Path]::ChangeExtension((Join-Path $root $tool.Path),$ext)) -Destination ([IO.Path]::ChangeExtension($bat,$ext))}
 $inputDir=Join-Path $dir 'Input';$output=Join-Path $dir 'Output';Ensure-Directory $inputDir;Ensure-Directory $output
 $leaf='ملف عربي & ! %X% [1]'
 try{
  foreach($arg in @('--help','--check')){$r=Run-Bat $bat $arg;Assert ($r.Code -eq 0) ($arg+': '+$r.Text)};Record ($tool.Name+' launch') $true 'Actual BAT help/check from a different working directory in relocated Arabic/metacharacter path.'
  $empty=Run-Bat $bat;Assert ($empty.Code -eq 0 -and $empty.Text -match 'No supported input') ('Empty input: '+$empty.Text);Record ($tool.Name+' empty') $true 'Empty Input handled without publishing output.'
  $answers='';$args='--defaults'
  switch($tool.Name){
   'PDF Search' {Copy-Fixture 'pages.pdf' (Join-Path $inputDir ($leaf+'.pdf'))}
   'PDF Add Page Numbers' {Copy-Fixture 'pages.pdf' (Join-Path $inputDir ($leaf+'.pdf'))}
   'PDF Protect' {Copy-Fixture 'pages.pdf' (Join-Path $inputDir ($leaf+'.pdf'));$answers=$password+"`n"+$password+"`n"}
   'PDF Unlock' {Copy-Fixture 'protected.pdf' (Join-Path $inputDir ($leaf+'.pdf'));$answers=$password+"`n"}
   'PDF Watermark' {Copy-Fixture 'pages.pdf' (Join-Path $inputDir ($leaf+'.pdf'))}
   'PDF Compare' {foreach($side in @('Left','Right')){Ensure-Directory (Join-Path $inputDir $side);Copy-Fixture 'pages.pdf' (Join-Path $inputDir ($side+'\'+$leaf+'.pdf'))}}
   'PDF Blank Page Remover' {Copy-Fixture 'blank.pdf' (Join-Path $inputDir ($leaf+'.pdf'))}
   'Files to ZIP by Size' {Copy-Fixture 'random.bin' (Join-Path $inputDir ($leaf+'.bin'));Ensure-Directory (Join-Path $inputDir 'مجلد');Copy-Fixture 'random.bin' (Join-Path $inputDir ('مجلد\'+$leaf+'.bin'));$args='';$answers="2`n1`n"}
   'File Type Organizer' {Copy-Fixture 'image.png' (Join-Path $inputDir ($leaf+'.png'));Ensure-Directory (Join-Path $inputDir 'رحلة');Copy-Fixture 'image.png' (Join-Path $inputDir ('رحلة\'+$leaf+'.png'));Copy-Fixture 'text.txt' (Join-Path $inputDir 'notes.txt')}
   'File Date Organizer' {Copy-Fixture 'image.png' (Join-Path $inputDir ($leaf+'.png'));(Get-Item -LiteralPath (Join-Path $inputDir ($leaf+'.png'))).LastWriteTime=Get-Date '2026-10-12T12:00:00'}
   'Video Contact Sheet' {Copy-Fixture 'video.mp4' (Join-Path $inputDir ($leaf+'.mp4'))}
   'Subtitle Tools' {Copy-Fixture 'text.srt' (Join-Path $inputDir ($leaf+'.srt'))}
  }
  $before=HashTree $inputDir;$r=Run-Bat $bat $args $answers
  Assert ($r.Code -eq 0 -and $r.Text -match 'SUCCESS') ('Processing failed: '+$r.Text)
  $outputs=@(Get-SafeFiles $output $null -Recurse);Assert ($outputs.Count -gt 0) 'No results.'
  $script:NativeWorkingDirectory=$fixtures
  switch($tool.Name){
   'PDF Search' {$rows=@(Import-Csv -LiteralPath (Join-Path $output 'search-report\matches.csv'));Assert ($rows.Count -eq 1 -and $rows[0].Page -eq '1' -and $rows[0].ExtractedLine.Contains('test PAGE ONE')) 'Search page/phrase incorrect.'}
   'PDF Add Page Numbers' {Assert ((PDF-Count $outputs[0].FullName) -eq 2) 'Numbering page count.';$t=Get-PDFText 'checked.pdf' 1;Assert ($t -match '\b1\b') ('Number not extractable: '+$t)}
   'PDF Protect' {[IO.File]::Copy($outputs[0].FullName,(Join-Path $fixtures 'output.pdf'),$true);$bad=Invoke-Native $qpdf @('@-') 0 ("output.pdf`n--password="+$wrong+"`n--check`n");Assert ($bad.Code -ne 0) 'Wrong password accepted.';$good=Invoke-QPDFJob $qpdf @{inputFile='output.pdf';password=$password;showNpages=''};Assert ($good.Out.Trim() -eq '2') 'Correct password/pages failed.';Assert (-not $r.Text.Contains($password)) 'Password leaked in log.'}
   'PDF Unlock' {Assert ((PDF-Count $outputs[0].FullName) -eq 2) 'Unlocked pages.';Assert ((Get-PDFText 'checked.pdf' 1).Contains('PAGE ONE')) 'Unlocked content lost.'}
   'PDF Watermark' {Assert ((PDF-Count $outputs[0].FullName) -eq 2) 'Watermark pages.';Render-PDFPage 'checked.pdf' 1 'watermarked.png' 72;Render-PDFPage 'pages.pdf' 1 'original.png' 72;$diff=Invoke-Native $magick @('compare','-metric','AE','original.png','watermarked.png','watermark-diff.png');Assert ($diff.Code -eq 1 -and [double]($diff.Err.Trim() -replace '\s.*$','') -gt 100) 'Watermark not visible.';Assert ((Get-PDFText 'checked.pdf' 1).Contains('PAGE ONE')) 'Source text layer lost.'}
   'PDF Compare' {$rows=@(Import-Csv -LiteralPath (Join-Path $output 'pdf-comparison\pages.csv'));Assert ($rows.Count -eq 2 -and @($rows|Where-Object Visual -ne 'Identical pixels').Count -eq 0) 'Identical PDF comparison incorrect.'}
   'PDF Blank Page Remover' {$rows=@(Import-Csv -LiteralPath $outputs.Where({$_.Name -eq 'preview.csv'})[0].FullName);Assert (@($rows|Where-Object Candidate -eq 'True').Count -eq 1 -and $rows[0].Candidate -eq 'True') 'Faint/edge/small mark incorrectly classified blank.';Assert (-not @($outputs|Where-Object Name -eq 'cleaned.pdf').Count) 'Default deleted a page.'}
   'Files to ZIP by Size' {$zips=@($outputs|Where-Object Extension -eq '.zip');Assert ($zips.Count -eq 2 -and @($zips|Where-Object Length -gt 1MB).Count -eq 0) 'ZIP size/partition wrong.';$rows=@(Import-Csv -LiteralPath (Join-Path $output 'zip-parts\index.csv'));Assert ($rows.Count -eq 2 -and @($rows|Where-Object {$_.File.Contains('\')}).Count -eq 1) 'ZIP index/hierarchy wrong.'}
   'File Type Organizer' {$rows=@(Import-Csv -LiteralPath (Join-Path $output 'organized-types\categories.csv'));Assert (($rows|Where-Object Category -eq 'Images').Count -eq '2' -and ($rows|Where-Object Category -eq 'Documents').Count -eq '1') 'Category totals incorrect.'}
   'File Date Organizer' {$rows=@(Import-Csv -LiteralPath (Join-Path $output 'organized-dates\dates.csv'));Assert ($rows[0].Copy.StartsWith('2026\10\') -and $rows[0].DateSource -eq 'Modification') ('Wrong date folders: '+$rows[0].Copy)}
   'Video Contact Sheet' {$rows=@(Import-Csv -LiteralPath $outputs.Where({$_.Name -eq 'timestamps.csv'})[0].FullName);Assert ($rows.Count -eq 12 -and [double]$rows[0].Seconds -lt [double]$rows[-1].Seconds) 'Contact sheet times not distributed.';$dims=Image-Info $outputs.Where({$_.Name -eq 'contact-sheet.jpg'})[0].FullName;Assert ($dims -eq '1312 642') ('Wrong contact sheet layout: '+$dims);[IO.File]::Copy($outputs.Where({$_.Name -eq 'contact-sheet.jpg'})[0].FullName,(Join-Path $fixtures 'sheet.jpg'),$true);[void](Invoke-Checked $magick @('sheet.jpg','-crop','320x180+4+4','+repage','tile-a.png'));[void](Invoke-Checked $magick @('sheet.jpg','-crop','320x180+332+4','+repage','tile-b.png'));$diff=Invoke-Native $magick @('compare','-metric','AE','tile-a.png','tile-b.png','tile-diff.png');Assert ($diff.Code -eq 1) 'Snapshot content is identical in a changing test video.'}
   'Subtitle Tools' {$j=Get-Content -LiteralPath $outputs.Where({$_.Name -eq 'summary.json'})[0].FullName -Raw|ConvertFrom-Json;Assert ($j.Cues -eq 2 -and $j.Issues -eq 0) 'Valid Arabic SRT not validated.'}
  }
  Assert ((HashTree $inputDir) -ceq $before) 'Original hashes changed.';$previous=HashTree $output;$again=Run-Bat $bat $args $answers;Assert ($again.Code -eq 0 -and (HashTree $output) -ceq $previous) 'Repeat changed earlier outputs.'
  Record ($tool.Name+' processing') $true 'Actual BAT operation, semantic output checks, original SHA-256 and repeated-output preservation.'
  $menu=Run-Bat $bat '' "1&whoami`nQ`n";Assert ($menu.Code -eq 0 -and $menu.Text -match 'Invalid selection') 'Unsafe menu input accepted.';Record ($tool.Name+' menu') $true 'Shell metacharacters rejected as menu input.'
  if($tool.Dependency){
   $bin=Join-Path $project 'System\Bin';$savedBin=Join-Path $project 'System\SavedBin'
   Assert ($bin.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe fixture move.'
   [IO.Directory]::Move($bin,$savedBin)
   try{$missing=Run-Bat $bat '--check' '' $true;Assert ($missing.Code -ne 0) 'Missing dependency accepted.'}finally{[IO.Directory]::Move($savedBin,$bin)}
   Record ($tool.Name+' missing dependency') $true 'Absent local/system dependencies refused without downloading.'
  }
  Assert ($inputDir.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe fixture move.'
  [IO.Directory]::Move($inputDir,($inputDir+'-saved'));[IO.Directory]::Move($output,($output+'-saved'));Ensure-Directory $inputDir;Ensure-Directory $output
  if($tool.Name -eq 'PDF Compare'){foreach($s in @('Left','Right')){Ensure-Directory (Join-Path $inputDir $s)};Copy-Fixture 'pages.pdf' (Join-Path $inputDir 'Left\good.pdf');$bad=Join-Path $inputDir 'Right\bad.pdf'}
  else{$extension=if($tool.Name -like 'PDF *'){'.pdf'}elseif($tool.Name -eq 'Subtitle Tools'){'.srt'}elseif($tool.Name -eq 'Video Contact Sheet'){'.mp4'}else{'.bin'};$bad=Join-Path $inputDir ('bad'+$extension)}
  [IO.File]::WriteAllText($bad,'not a valid media/subtitle document');$badHash=(Get-FileHash -LiteralPath $bad).Hash
  $badAnswers=$answers;$badArgs=$args;if($tool.Name -eq 'Files to ZIP by Size'){$badAnswers='';$badArgs='--defaults'}
  $invalid=Run-Bat $bat $badArgs $badAnswers
  if($tool.Name -in @('Files to ZIP by Size','File Type Organizer','File Date Organizer')){Assert ($invalid.Code -eq 0) 'Opaque binary file was not handled safely.'}
  elseif($tool.Name -eq 'Subtitle Tools'){$j=Get-Content -LiteralPath (Join-Path $output 'bad.srt.subtitles\summary.json') -Raw|ConvertFrom-Json;Assert ($j.Fatal -gt 0) 'Malformed SRT not reported.'}
  else{Assert ($invalid.Code -ne 0 -and -not @(Get-SafeFiles $output $null -Recurse).Count) 'Corrupt media published a result.'}
  Assert ((Get-FileHash -LiteralPath $bad).Hash -eq $badHash) 'Corrupt source changed.';Record ($tool.Name+' invalid input') $true 'Corrupt media refused or opaque file handled according to tool semantics; source bytes preserved.'
 }catch{Record $tool.Name $false $_.Exception.Message}
}
@{Date=[datetime]::Now.ToString('o');Phase=$Phase;Sandbox=$work.Replace($root,'<PROJECT_ROOT>');Windows=[Environment]::OSVersion.Version.ToString();PowerShell=$PSVersionTable.PSVersion.ToString();Results=$results.ToArray()}|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $PSScriptRoot ('hundred-phase'+$Phase+'-results.json')) -Encoding UTF8
if(@($results|Where-Object{-not $_.Passed}).Count){exit 1};exit 0
