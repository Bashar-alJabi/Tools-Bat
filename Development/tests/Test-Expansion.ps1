param([ValidateSet('A','B','All')][string]$Batch='A',[string]$Only)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
$root=$script:ProjectRoot
$catalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
$catalog=@($catalog|Where-Object {$_.PSObject.Properties['Expansion'] -and ($Batch -eq 'All' -or $_.Expansion -eq ('2026-10-20-'+$Batch)) -and (-not $Only -or $_.Name -eq $Only)})
if(-not $catalog.Count){throw 'No expansion tools selected.'}
$work=Join-Path $PSScriptRoot ('_work\e-'+[guid]::NewGuid().ToString('N').Substring(0,8));Ensure-Directory $work
$arabic=-join([char[]]@(0x0639,0x0631,0x0628,0x064A))
$project=Join-Path $work ('p '+$arabic+' & ! %X% [1]');Ensure-Directory (Join-Path $project 'System')
Copy-Item -LiteralPath (Join-Path $root 'System\Shared') -Destination (Join-Path $project 'System\Shared') -Recurse
$fixtures=Join-Path $work 'f';Ensure-Directory $fixtures;$script:NativeWorkingDirectory=$fixtures
$results=New-Object 'Collections.Generic.List[object]'
function Assert([bool]$Value,[string]$Message){if(-not $Value){throw $Message}}
function Record([string]$Name,[bool]$Passed,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$Passed;Detail=$Detail.Replace($root,'<PROJECT_ROOT>')});Write-Host ($(if($Passed){'PASS '}else{'FAIL '})+$Name+': '+$Detail)}
function Run-Bat([string]$Path,[string]$Arguments='--defaults',[string]$Answers='',[bool]$LocalOnly=$false){
 $info=New-Object Diagnostics.ProcessStartInfo;$info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe'
 $info.Arguments='/d /v:off /s /c ""%TB_EXP_BAT%" '+$Arguments+'"';$info.WorkingDirectory=$fixtures;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
 $info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
 $info.EnvironmentVariables['TB_EXP_BAT']=$Path;$info.EnvironmentVariables['TB_NO_PAUSE']='1';$info.EnvironmentVariables['TB_LOCAL_ONLY']=$(if($LocalOnly){'1'}else{'0'})
 $info.EnvironmentVariables['PSModulePath']=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules'
 $p=New-Object Diagnostics.Process;$p.StartInfo=$info
 try{[void]$p.Start();$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();if($Answers){$p.StandardInput.Write($Answers)};$p.StandardInput.Close();if(-not $p.WaitForExit(120000)){$p.Kill();throw 'BAT timed out.'};$p.WaitForExit();[pscustomobject]@{Code=$p.ExitCode;Text=$out.Result+$err.Result}}finally{$p.Dispose()}
}
function HashTree([string]$Path){@(Get-SafeFiles $Path $null -Recurse|Sort-Object FullName|ForEach-Object{(Get-RelativeName $Path $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"}
function Probe([string]$Path){(Invoke-Checked $probe @('-v','error','-show_streams','-show_format','-of','json',$Path))|ConvertFrom-Json}
function Image-Info([string]$Path,[string]$Format='%w %h'){
 $alias='checked'+[IO.Path]::GetExtension($Path);[IO.File]::Copy($Path,(Join-Path $fixtures $alias),$true)
 (Invoke-Checked $magick @('identify','-format',$Format,$alias)).Trim()
}
function PDF-Count([string]$Path){
 [IO.File]::Copy($Path,(Join-Path $fixtures 'checked.pdf'),$true)
 [int](Invoke-Checked $gs @('-q','-dSAFER','-dNODISPLAY','--permit-file-read=checked.pdf','-c','(checked.pdf) (r) file runpdfbegin pdfpagecount = quit')).Trim()
}
function Copy-Fixture([string]$Name,[string]$Target){Ensure-Directory ([IO.Path]::GetDirectoryName($Target));[IO.File]::Copy((Join-Path $fixtures $Name),$Target,$false)}
function Prepare-SpecialFolders([string]$Directory,[string]$ToolName){
 Ensure-Directory $Directory
 if($ToolName -eq 'Image Compare'){Ensure-Directory (Join-Path $Directory 'Left');Ensure-Directory (Join-Path $Directory 'Right')}
 if($ToolName -in @('Video Subtitles Burn','Video Add Subtitle Track')){Ensure-Directory (Join-Path $Directory 'Subtitles')}
}
try{
 $ff=Require-Dependency 'ffmpeg';$probe=Require-Dependency 'ffprobe';$magick=Require-Dependency 'magick';$gs=Require-Dependency 'ghostscript'
 [void](Invoke-Checked $magick @('-size','96x64','gradient:black-white','-rotate','90','-resize','96x64!','pattern.png'))
 [void](Invoke-Checked $magick @('pattern.png','-resize','48x32','pattern.jpg'))
 [void](Invoke-Checked $magick @('-size','96x64','xc:red','-fill','blue','-draw','rectangle 48,0 95,63','colors.png'))
 [void](Invoke-Checked $magick @('colors.png','-fill','white','-draw','rectangle 10,10 20,20','changed.png'))
 [void](Invoke-Checked $magick @('-size','80x40','xc:red','-orient','RightTop','oriented.tif'))
 [void](Invoke-Checked $magick @('-size','20x20','xc:white','logo.png'))
 [void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-f','lavfi','-i',"color=red:s=96x64:r=10:d=2,drawbox=x=16:y=16:w=32:h=32:color=blue:t=fill:enable='gte(t,1)'",'-f','lavfi','-i','sine=frequency=440:duration=2','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac','-shortest','video.mp4'))
 [void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-f','lavfi','-i','color=red:s=64x32:r=10:d=2,pad=96:64:16:16:black','-an','-c:v','libx264','-pix_fmt','yuv420p','bars.mp4'))
 $subtitle="1`r`n00:00:00,100 --> 00:00:01,900`r`n"+$arabic+" TEST`r`n";[IO.File]::WriteAllText((Join-Path $fixtures 'text.srt'),$subtitle,(New-Object Text.UTF8Encoding($false)))
 [void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-i','video.mp4','-i','text.srt','-map','0:v','-map','0:a','-map','1:0','-c','copy','-c:s','srt','embedded.mkv'))
 foreach($tool in $catalog){
  try{
   $bat=Join-Path $project $tool.Path;$dir=Split-Path $bat;Ensure-Directory $dir
   foreach($ext in @('.bat','.ps1','.md')){$source=[IO.Path]::ChangeExtension((Join-Path $root $tool.Path),$ext);[IO.File]::Copy($source,[IO.Path]::ChangeExtension($bat,$ext),$false)}
   $inputDir=Join-Path $dir 'Input';$output=Join-Path $dir 'Output';Prepare-SpecialFolders $inputDir $tool.Name;Ensure-Directory $output
   $name=$arabic+' & ! %X% [1]'
   switch($tool.Name){
    'Image Duplicates' {Copy-Fixture 'pattern.png' (Join-Path $inputDir ($name+'.png'));Copy-Fixture 'pattern.png' (Join-Path $inputDir 'copy.png');Copy-Fixture 'pattern.jpg' (Join-Path $inputDir 'small.jpg')}
    'Image to PDF' {Copy-Fixture 'pattern.png' (Join-Path $inputDir '001.png');Copy-Fixture 'colors.png' (Join-Path $inputDir '002.png')}
    'Image Compare' {Copy-Fixture 'colors.png' (Join-Path $inputDir ('Left\'+$name+'.png'));Copy-Fixture 'changed.png' (Join-Path $inputDir 'Right\changed.png')}
    'Image Collage' {Copy-Fixture 'colors.png' (Join-Path $inputDir '001.png');Copy-Fixture 'pattern.png' (Join-Path $inputDir '002.png');Copy-Fixture 'changed.png' (Join-Path $inputDir '003.png')}
    'Image Auto Orient' {Copy-Fixture 'colors.png' (Join-Path $inputDir ($name+'.png'));Copy-Fixture 'oriented.tif' (Join-Path $inputDir 'oriented.tif')}
    'Image Color Palette' {Copy-Fixture 'colors.png' (Join-Path $inputDir ($name+'.png'))}
    'Image Format Report' {Copy-Fixture 'pattern.jpg' (Join-Path $inputDir 'one.jpg');Copy-Fixture 'colors.png' (Join-Path $inputDir 'two.png')}
    'Video Merge' {Copy-Fixture 'video.mp4' (Join-Path $inputDir '001.mp4');Copy-Fixture 'video.mp4' (Join-Path $inputDir '002.mp4')}
    'Video Watermark' {Copy-Fixture 'video.mp4' (Join-Path $inputDir ($name+'.mp4'));Copy-Fixture 'logo.png' (Join-Path $dir 'Watermark\logo.png')}
    'Video Extract Subtitles' {Copy-Fixture 'embedded.mkv' (Join-Path $inputDir ($name+'.mkv'))}
    'Video Remove Black Bars' {Copy-Fixture 'bars.mp4' (Join-Path $inputDir ($name+'.mp4'))}
    'Video Subtitles Burn' {[void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-i','video.mp4','-vf','scale=640:360','-c:v','libx264','-c:a','copy','subtitle-video.mp4'));Copy-Fixture 'subtitle-video.mp4' (Join-Path $inputDir ($name+'.mp4'));Copy-Fixture 'text.srt' (Join-Path $inputDir ('Subtitles\'+$name+'.srt'))}
    'Video Add Subtitle Track' {Copy-Fixture 'video.mp4' (Join-Path $inputDir ($name+'.mp4'));Copy-Fixture 'text.srt' (Join-Path $inputDir ('Subtitles\'+$name+'.srt'))}
    default {Copy-Fixture 'video.mp4' (Join-Path $inputDir ($name+'.mp4'))}
   }
   $before=HashTree $inputDir
   $run=Run-Bat $bat '--help';Assert ($run.Code -eq 0) ('Help failed: '+$run.Text)
   $run=Run-Bat $bat '--check';Assert ($run.Code -eq 0) ('Check failed: '+$run.Text)
   $run=Run-Bat $bat;Assert ($run.Code -eq 0 -and $run.Text -match '\[SUCCESS\]') ('Processing failed: '+$run.Text)
   $outputs=@(Get-SafeFiles $output $null -Recurse);Assert ($outputs.Count -gt 0) 'No output.'
   switch($tool.Name){
    'Image Duplicates' {$rows=@(Import-Csv -LiteralPath (Join-Path $output 'similarity\pairs.csv'));Assert (@($rows|Where-Object Match -eq 'BytesIdentical').Count -ge 1 -and @($rows|Where-Object Match -eq 'Approximate').Count -ge 1) 'Exact/approximate distinction missing.'}
    'Image to PDF' {Assert ((PDF-Count (Join-Path $output 'images.pdf')) -eq 2) 'PDF page count wrong.'}
    'Image Compare' {$row=Import-Csv -LiteralPath (Join-Path $output 'difference\comparison.csv');Assert ([double]$row.NormalizedRMSE -gt 0 -and $row.IdenticalPixels -eq 'False') 'RMSE comparison wrong.';Assert ((Image-Info (Join-Path $output 'difference\diff.png')) -eq '96 64') 'Difference dimensions wrong.'}
    'Image Collage' {Assert ((Image-Info (Join-Path $output 'collage.png')) -eq '1200 800') 'Collage canvas wrong.'}
    'Image Auto Orient' {$corrected=Join-Path $output 'oriented.tif.oriented.tif';Assert ((Image-Info $corrected) -eq '40 80') 'Orientation was not applied.';Assert ((Get-FileHash -LiteralPath (Join-Path $output ($name+'.png.oriented.png'))).Hash -eq (Get-FileHash -LiteralPath (Join-Path $inputDir ($name+'.png'))).Hash) 'Unneeded orientation recompressed the source.'}
    'Image Color Palette' {$rows=@(Import-Csv -LiteralPath (Join-Path $output ($name+'.png.palette\colors.csv')));Assert ($rows.Count -eq 2 -and [long]($rows|Measure-Object Pixels -Sum).Sum -eq 6144) 'Palette counts wrong.'}
    'Image Format Report' {$summary=Get-Content -LiteralPath (Join-Path $output 'image-report\summary.json') -Raw|ConvertFrom-Json;Assert ($summary.Count -eq 2 -and $summary.CountsByFormat.Count -eq 2 -and $summary.TotalBytes -eq [long](Get-ChildItem -LiteralPath $inputDir -File|Measure-Object Length -Sum).Sum) 'Image aggregate statistics wrong.'}
    'Video Merge' {$p=Probe (Join-Path $output 'merged.mp4');Assert ([double]$p.format.duration -gt 3.9 -and $run.Text -match 'direct copy') 'Merge did not choose direct copy or duration is wrong.'}
    'Video Screenshot at Time' {Assert ((Image-Info $outputs[0].FullName) -eq '96 64') 'Screenshot dimensions wrong.';[void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-i','video.mp4','-ss','1','-frames:v','1','expected.png'));$expected=Invoke-Checked $ff @('-v','error','-i','expected.png','-f','md5','-');$actual=Invoke-Checked $ff @('-v','error','-i',$outputs[0].FullName,'-f','md5','-');Assert ($expected.Trim() -eq $actual.Trim()) 'Screenshot selected wrong time.'}
    'Video Watermark' {Assert ((Probe $outputs[0].FullName).streams[0].width -eq 96) 'Watermark dimensions wrong.';[void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-i',$outputs[0].FullName,'-frames:v','1','watermark.png'));$green=Invoke-Checked $magick @('watermark.png','-format','%[fx:p{90,60}.g]','info:');Assert ([double]$green -gt 0.3) 'Logo not present at bottom right.'}
    'Video Subtitles Burn' {[void](Invoke-Checked $ff @('-v','error','-nostdin','-n','-i',$outputs[0].FullName,'-ss','0.5','-frames:v','1','burn.png'));$green=Invoke-Checked $magick @('burn.png','-format','%[fx:maxima.g]','info:');Assert ([double]$green -gt 0.5) 'Subtitle glyph pixels not rendered.'}
    'Video Extract Subtitles' {$srt=@($outputs|Where-Object Extension -eq '.srt');Assert ($srt.Count -eq 1 -and [IO.File]::ReadAllText($srt[0].FullName).Contains('TEST')) 'Embedded text not extracted.'}
    'Video Add Subtitle Track' {$tracks=@((Probe $outputs[0].FullName).streams|Where-Object codec_type -eq 'subtitle');Assert ($tracks.Count -eq 1 -and $tracks[0].codec_name -eq 'subrip') 'Selectable subtitle stream missing.'}
    'Video Remove Black Bars' {$row=Import-Csv -LiteralPath (Join-Path $output ($name+'.mp4.crop-preview\crop.csv'));Assert ([int]$row.CropWidth -eq 64 -and [int]$row.CropHeight -eq 32) 'Detected crop differs from fixture borders.';Assert (-not @($outputs|Where-Object Extension -eq '.mp4').Count) 'Default mode unexpectedly cropped a video.'}
    'Video Audio Sync' {$p=Probe $outputs[0].FullName;Assert ([Math]::Abs([double]$p.format.duration-2) -lt 0.15) 'Synced duration wrong.';$vol=Invoke-Native $ff @('-v','info','-i',$outputs[0].FullName,'-t','0.15','-af','volumedetect','-f','null','-');Assert ($vol.Err -match 'mean_volume: (-inf|-[789]\d(?:\.\d+)?) dB') 'Positive offset did not insert leading silence.'}
   }
   Assert ((HashTree $inputDir) -eq $before) 'Original inputs changed.'
   $prior=HashTree $output;$repeat=Run-Bat $bat;Assert ($repeat.Code -eq 0 -and (HashTree $output) -eq $prior) 'Repeat overwrote output.'
   Record $tool.Name $true 'BAT help/check/processing/repeat in relocated Unicode/metacharacter path; semantic content verified; originals and existing outputs preserved.'
   $menu=Run-Bat $bat '' "1&whoami`nQ`n";Assert ($menu.Code -eq 0 -and $menu.Text -match 'Invalid selection') 'Menu validation failed.';Record ($tool.Name+' menu') $true 'Metacharacter input refused; Q exits without processing.'
   if($tool.Dependency){$missing=Run-Bat $bat '--check' '' $true;Assert ($missing.Code -ne 0) 'Absent dependency accepted.';Record ($tool.Name+' missing dependency') $true 'Local-only discovery refused missing programs; no download.'}
   # Relocate only our freshly generated fixture trees; keep good outputs intact.
   $saved=Join-Path $fixtures ('saved-'+($tool.Name -replace ' ',''));$failed=Join-Path $fixtures ('invalid-'+($tool.Name -replace ' ',''));Ensure-Directory $saved;Ensure-Directory $failed
   Assert ($inputDir.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase) -and $output.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe fixture move.'
   [IO.Directory]::Move($inputDir,(Join-Path $saved 'Input'));[IO.Directory]::Move($output,(Join-Path $saved 'Output'))
   Prepare-SpecialFolders $inputDir $tool.Name;Ensure-Directory $output
   $empty=Run-Bat $bat;Assert ($empty.Code -eq 0 -and $empty.Text -match 'No supported input') ('Empty input failed: '+$empty.Text);Record ($tool.Name+' empty') $true 'Empty Input exits safely with no output.'
   if($tool.Name -eq 'Image Compare'){Copy-Fixture 'colors.png' (Join-Path $inputDir 'Right\good.png');$bad=Join-Path $inputDir 'Left\bad.png'}
   else{$ext=if($tool.Path -match '\\IMG\\'){'.png'}else{'.mp4'};$bad=Join-Path $inputDir ('bad'+$ext)}
   if($tool.Name -in @('Video Subtitles Burn','Video Add Subtitle Track')){Copy-Fixture 'text.srt' (Join-Path $inputDir 'Subtitles\bad.srt')}
   [IO.File]::WriteAllText($bad,'not a supported media file');$badHash=(Get-FileHash -LiteralPath $bad).Hash
   $invalid=Run-Bat $bat;Assert ($invalid.Code -in @(1,2) -and -not @(Get-SafeFiles $output $null -Recurse).Count) ('Corrupt input accepted: '+$invalid.Text)
   Assert ((Get-FileHash -LiteralPath $bad).Hash -eq $badHash) 'Corrupt input was modified.';Record ($tool.Name+' corrupt') $true 'Rejected invalid input without publishing a partial result.'
   [IO.Directory]::Move($inputDir,(Join-Path $failed 'Input'));[IO.Directory]::Move($output,(Join-Path $failed 'Output'));[IO.Directory]::Move((Join-Path $saved 'Input'),$inputDir);[IO.Directory]::Move((Join-Path $saved 'Output'),$output)
  }catch{Record $tool.Name $false $_.Exception.Message}
 }
}catch{Record 'Harness' $false $_.Exception.Message}
$suffix=if($Only){'-'+($Only -replace '[^a-zA-Z0-9]','')}else{''}
[pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Batch=$Batch;Windows=[Environment]::OSVersion.Version.ToString();PowerShell=$PSVersionTable.PSVersion.ToString();Results=$results}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot ('expansion-'+$Batch+$suffix+'-results.json')) -Encoding UTF8
Write-Host ('Passed '+@($results|Where-Object Passed).Count+'; Failed '+@($results|Where-Object {-not $_.Passed}).Count)
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
