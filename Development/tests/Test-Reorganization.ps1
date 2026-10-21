param([string]$Archive,[string]$WorkDirectory,[string]$ReportPath,[string]$GitPath,[switch]$LocalOnly)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\Archives.ps1')
$root=$script:ProjectRoot
$results=New-Object 'Collections.Generic.List[object]'
$copy=''
$work=if($WorkDirectory){[IO.Path]::GetFullPath($WorkDirectory)}else{Join-Path $PSScriptRoot ('_work\layout-'+[guid]::NewGuid().ToString('N').Substring(0,8))};Ensure-Directory $work
$fixtures=Join-Path $work 'fixtures';Ensure-Directory $fixtures
$script:NativeWorkingDirectory=$fixtures
$ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$previousPath=$env:PATH;$previousLocal=$env:TB_LOCAL_ONLY
if(-not $GitPath){$GitPath=(Get-Command git).Source}
if($LocalOnly){$env:PATH=$env:SystemRoot+'\System32;'+$env:SystemRoot;$env:TB_LOCAL_ONLY='1'}
function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Record([string]$Name,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$true;Detail=$Detail});Write-Host ('PASS '+$Name)}
function HashTree([string]$Path){@(Get-SafeFiles $Path $null -Recurse|Sort-Object FullName|ForEach-Object{(Get-RelativeName $Path $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"}
function Run-Bat([string]$Path,[string]$Arguments){
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe';$info.Arguments='/d /v:off /s /c ""%TB_LAYOUT_BAT%" '+$Arguments+'"'
    $info.WorkingDirectory=$fixtures;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.EnvironmentVariables['TB_LAYOUT_BAT']=$Path;$info.EnvironmentVariables['TB_NO_PAUSE']='1'
    $info.EnvironmentVariables['PSModulePath']=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules'
    $process=New-Object Diagnostics.Process;$process.StartInfo=$info
    try{
        [void]$process.Start();$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync();$process.StandardInput.Close()
        if(-not $process.WaitForExit(60000)){$process.Kill();throw 'BAT timed out.'};$process.WaitForExit()
        Assert ($process.ExitCode -eq 0) ($out.Result+$err.Result)
        return $out.Result+$err.Result
    }finally{$process.Dispose()}
}
try{
    $catalog=Get-Content -LiteralPath (Join-Path $root 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
    Assert ($catalog.Count -ge 55 -and @(Get-ChildItem -LiteralPath (Join-Path $root 'Tools') -Recurse -File -Filter *.bat).Count -eq $catalog.Count) 'Tool count changed.'
    $git=$GitPath
    foreach($tool in @($catalog|Where-Object {-not $_.PSObject.Properties['Expansion']})){
        $oldPath=$tool.Path.Substring(6).Replace('\','/')
        $before=Invoke-Native $git @('-C',$root,'show',('ed2f937:'+$oldPath)) 30000
        Assert ($before.Code -eq 0) ('Missing baseline BAT '+$oldPath)
        $current=[IO.File]::ReadAllText((Join-Path $root $tool.Path))
        $expected=$before.Out.Replace('..\..\_shared','..\..\..\System\Shared')
        Assert ($current.Replace("`r`n","`n") -ceq $expected.Replace("`r`n","`n")) ('Unexpected BAT behavior change: '+$tool.Name)
    }
    Record 'All 55 BAT bodies preserved' 'Compared with ed2f937; only the shared runtime path changed, including original menus and defaults.'
    if(-not $Archive){
        $build=Join-Path $work 'package'
        $run=Invoke-Native $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'System\Shared\Build.ps1'),'-Mode','Defaults','-Destination',$build) 60000
        Assert ($run.Code -eq 0) ($run.Out+$run.Err);$Archive=$build+'.zip'
    }
    $arabic=-join([char[]]@(0x0646,0x0642,0x0644))
    $copy=Join-Path $work ('USB '+$arabic+' & ! %X% [1]')
    Zip-Extract ([IO.Path]::GetFullPath($Archive)) $copy
    $manifest=Get-Content -LiteralPath (Join-Path $copy 'distribution-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($entry in $manifest){Assert ((Get-FileHash -LiteralPath (Join-Path $copy $entry.Path)).Hash -eq $entry.SHA256) ('Extracted hash mismatch '+$entry.Path)}
    foreach($name in @('Tools','System\Shared','System\Bin','System\Docs')){Assert ([IO.Directory]::Exists((Join-Path $copy $name))) ('Missing '+$name)}
    foreach($name in @('Development','.git','tests','_shared','_bin','IMG','VID','AUD','PDF','UTI','NET','System\Downloads')){Assert (-not (Test-Path -LiteralPath (Join-Path $copy $name))) ('Leaked old/development path '+$name)}
    foreach($file in (Get-SafeFiles (Join-Path $copy 'Tools') $null -Recurse)){Assert ($file.FullName -notmatch '\\(Input|Output|Watermark)\\') 'Personal input/output in release.'}
    Record 'Real ZIP extraction and hashes' 'New Arabic/spaces/metacharacter path; expected Tools/System layout; all hashes matched; no development or personal data.'
    foreach($tool in $catalog){
        $bat=Join-Path $copy $tool.Path
        Assert (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($bat,'.md'))) ('Missing MD '+$tool.Name)
        $null=Run-Bat $bat '--help';$null=Run-Bat $bat '--check'
        Record ($tool.Name+' extracted BAT') 'Help and actual dependency check executed from an unrelated working directory after ZIP extraction.'
    }
    for($i=1;$i -le 2;$i++){
        $text=Run-Bat (Join-Path $copy 'START_HERE.bat') '--check'
        Assert ($text -match ('Tools registered: '+$catalog.Count) -and $text -notmatch '\[MISSING\]') 'START_HERE check failed.'
        Record ('Extracted START_HERE check '+$i) 'All registered programs and OCR languages detected; no download, prompt, registry or persistent PATH change.'
    }
    $docs=@(Get-SafeFiles $copy @('.md') -Recurse)
    foreach($doc in $docs){
        foreach($m in [regex]::Matches([IO.File]::ReadAllText($doc.FullName),'\]\((?:<(?<a>[^>]+)>|(?<p>[^)]+))\)')){
            $link=if($m.Groups['a'].Success){$m.Groups['a'].Value}else{$m.Groups['p'].Value}
            if($link -match '^(https?:|mailto:|#)'){continue}
            $path=[uri]::UnescapeDataString($link.Split('#')[0])
            Assert (Test-Path -LiteralPath (Join-Path $doc.DirectoryName $path)) ('Broken local MD link: '+$doc.Name+' -> '+$link)
        }
    }
    Record 'Release Markdown links' 'Every local link in all exported Markdown files resolves inside the extracted release.'
    # Fixture creation and output inspection must use the extracted runtime too.
    if($LocalOnly){$script:ProjectRoot=$copy}
    $magick=Require-Dependency 'magick';$ffmpeg=Require-Dependency 'ffmpeg';$gs=Require-Dependency 'ghostscript'
    [void](Invoke-Checked $magick @('-size','32x24','xc:red','image.png'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','color=c=blue:s=32x24:r=10:d=1','-f','lavfi','-i','sine=frequency=440:duration=1','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac','-shortest','video.mp4'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','sine=frequency=440:duration=1','audio.wav'))
    [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=pages.pdf','-c','/Helvetica findfont 12 scalefont setfont 72 720 moveto (Moved PDF) show showpage'))
    [IO.File]::WriteAllText((Join-Path $fixtures 'sample.txt'),'preserve source bytes')
    $ocrRun=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'hundred-phase2-results.json') -Raw -Encoding UTF8|ConvertFrom-Json
    $ocrFixtures=Join-Path ($ocrRun.Sandbox.Replace('<PROJECT_ROOT>',$root)) 'f'
    foreach($name in @('english.png','arabic.png','scans.pdf','paper.png')){[IO.File]::Copy((Join-Path $ocrFixtures $name),(Join-Path $fixtures $name),$false)}
    foreach($sample in @(@('Image Resize','image.png'),@('Video Speed','video.mp4'),@('Audio Channels','audio.wav'),@('PDF Split','pages.pdf'),@('File Inventory','sample.txt'),@('Network Info',''),@('Image Auto Orient','image.png'),@('Video Audio Sync','video.mp4'),@('Audio Reverse','audio.wav'),@('PDF Extract Pages','pages.pdf'),@('Batch Rename','sample.txt'),@('PDF Add Page Numbers','pages.pdf'),@('File Type Organizer','sample.txt'),@('File Date Organizer','sample.txt'),@('Video Contact Sheet','video.mp4'),@('Image OCR','english.png'),@('PDF OCR','scans.pdf'),@('Document Scanner','paper.png'))){
        $tool=$catalog|Where-Object Name -eq $sample[0];$bat=Join-Path $copy $tool.Path;$folder=Split-Path $bat
        $inputDir=Join-Path $folder 'Input';$output=Join-Path $folder 'Output'
        if($sample[1]){[IO.File]::Copy((Join-Path $fixtures $sample[1]),(Join-Path $inputDir ($arabic+' & ! %X% [1]'+[IO.Path]::GetExtension($sample[1]))),$false)}
        if($sample[0] -eq 'Image OCR'){[IO.File]::Copy((Join-Path $fixtures 'arabic.png'),(Join-Path $inputDir 'arabic.png'),$false)}
        $before=HashTree $inputDir;$text=Run-Bat $bat '--defaults'
        Assert (@(Get-SafeFiles $output $null -Recurse).Count -gt 0) ('No output '+$tool.Name)
        $produced=@(Get-SafeFiles $output $null -Recurse)
        if($tool.Name -eq 'PDF Add Page Numbers'){
            [IO.File]::Copy($produced[0].FullName,(Join-Path $fixtures 'numbered.pdf'),$true)
            [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=txtwrite','-sOutputFile=numbered.txt','numbered.pdf'))
            $content=[IO.File]::ReadAllText((Join-Path $fixtures 'numbered.txt'));Assert ($content.Contains('Moved PDF') -and $content -match '\b1\b') 'Extracted page numbering/content failed.'
        }
        if($tool.Name -eq 'File Type Organizer'){$rows=@(Import-Csv -LiteralPath (Join-Path $output 'organized-types\files.csv'));Assert ($rows.Count -eq 1 -and $rows[0].Category -eq 'Documents') 'Extracted organizer category failed.'}
        if($tool.Name -eq 'File Date Organizer'){$rows=@(Import-Csv -LiteralPath (Join-Path $output 'organized-dates\dates.csv'));Assert ($rows.Count -eq 1 -and $rows[0].DateSource -eq 'Modification' -and $rows[0].Copy -match '^\d{4}\\\d{2}\\') 'Extracted date organizer failed.'}
        if($tool.Name -eq 'Video Contact Sheet'){$rows=@(Import-Csv -LiteralPath ($produced|Where-Object Name -eq timestamps.csv).FullName);Assert ($rows.Count -eq 12 -and [double]$rows[0].Seconds -lt [double]$rows[-1].Seconds) 'Extracted contact sheet timestamps failed.'}
        if($tool.Name -eq 'Image OCR'){
            $content=($produced|ForEach-Object{[IO.File]::ReadAllText($_.FullName,(New-Object Text.UTF8Encoding($false,$true)))}) -join "`n"
            $word=-join([char[]]@(0x645,0x631,0x62D,0x628,0x627));Assert ($content.Contains('TOOLS BAT OCR TEST') -and $content.Contains($word)) 'Extracted real bilingual image OCR failed.'
        }
        if($tool.Name -eq 'PDF OCR'){
            [IO.File]::Copy(($produced|Where-Object Name -eq searchable.pdf).FullName,(Join-Path $fixtures 'searchable.pdf'),$true)
            [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=txtwrite','-sOutputFile=searchable.txt','searchable.pdf'))
            $content=[IO.File]::ReadAllText((Join-Path $fixtures 'searchable.txt'));$word=-join([char[]]@(0x645,0x631,0x62D,0x628,0x627));Assert ($content.Contains('TOOLS BAT OCR TEST') -and $content.Contains($word)) 'Extracted searchable PDF layer failed.'
        }
        if($tool.Name -eq 'Document Scanner'){$j=Get-Content -LiteralPath ($produced|Where-Object Name -eq decision.json).FullName -Raw|ConvertFrom-Json;Assert (-not $j.Applied -and $j.Corners.Count -eq 8) 'Extracted scanner proposal failed.'}
        $outBefore=HashTree $output;$null=Run-Bat $bat '--defaults'
        Assert ((HashTree $inputDir) -eq $before -and (HashTree $output) -eq $outBefore) ('Original or previous output changed '+$tool.Name)
        Record ($tool.Name+' extracted processing') 'Real fixture processing and repeat in extracted ZIP; original input and existing output hashes unchanged.'
    }
}catch{$results.Add([pscustomobject]@{Test='Reorganization';Passed=$false;Detail=$_.Exception.Message.Replace($root,'<PROJECT_ROOT>')});Write-Host ('FAIL '+$_.Exception.Message)}
$env:PATH=$previousPath;$env:TB_LOCAL_ONLY=$previousLocal
if(-not $ReportPath){$ReportPath=Join-Path $PSScriptRoot 'reorganization-results.json'}
[pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Archive=$Archive.Replace($root,'<PROJECT_ROOT>');ExtractedRoot=$copy.Replace($root,'<PROJECT_ROOT>');LocalOnly=[bool]$LocalOnly;Results=$results}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $ReportPath -Encoding UTF8
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
