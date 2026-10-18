param([switch]$Quick)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\_shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\_shared\Archives.ps1')
. (Join-Path $PSScriptRoot '..\_shared\Download.ps1')
$sourceRoot=$script:ProjectRoot
$catalog=Get-Content -LiteralPath (Join-Path $sourceRoot '_shared\tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$catalog=@($catalog | Where-Object {-not ($_.PSObject.Properties['Standalone'] -and $_.Standalone)})
$runRoot=Join-Path $PSScriptRoot ('_sandbox\run-' + [guid]::NewGuid().ToString('N'))
$arabicDirectory=-join ([char[]]@(0x0646,0x0642,0x0644))
$project=Join-Path $runRoot ('Portable '+$arabicDirectory+' (1) & ! %TB_UNDEFINED% [ar]')
$fixtures=Join-Path $runRoot 'fixtures'
Ensure-Directory $project; Ensure-Directory $fixtures
$script:NativeWorkingDirectory=$fixtures
Copy-Item -LiteralPath (Join-Path $sourceRoot '_shared') -Destination (Join-Path $project '_shared') -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot 'START_HERE.bat') -Destination (Join-Path $project 'START_HERE.bat')
$script:Results=New-Object 'Collections.Generic.List[object]'
function Record([string]$Name,[bool]$Passed,[string]$Detail) {
    $script:Results.Add([pscustomobject]@{Test=$Name;Passed=$Passed;Detail=$Detail})
    Write-Host (('{0} {1}: {2}' -f $(if($Passed){'PASS'}else{'FAIL'}),$Name,$Detail))
}
function Assert([bool]$Condition,[string]$Message) { if(-not $Condition){throw $Message} }
function Run-Bat([string]$Path,[string]$Arguments='--defaults',[string]$InputText='', [bool]$LocalOnly=$false) {
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe'
    $info.Arguments='/d /v:off /s /c ""%TB_TEST_BAT%" ' + $Arguments + '"'
    $info.WorkingDirectory=$fixtures
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardInput=$true; $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $info.EnvironmentVariables['TB_TEST_BAT']=$Path
    $info.EnvironmentVariables['TB_NO_PAUSE']='1'
    $info.EnvironmentVariables['TB_LOCAL_ONLY']=$(if($LocalOnly){'1'}else{'0'})
    foreach($name in @('FORMAT','QUALITY','WIDTH','HEIGHT','RATIO','MODE','COUNT','SIZE','TYPE','OPACITY','SPEED','LABEL','FPS','COLOR','FUZZ')) { $info.EnvironmentVariables.Remove($name) }
    $process=New-Object Diagnostics.Process
    $process.StartInfo=$info
    try {
        [void]$process.Start()
        $outTask=$process.StandardOutput.ReadToEndAsync(); $errTask=$process.StandardError.ReadToEndAsync()
        if($InputText){$process.StandardInput.Write($InputText)}
        $process.StandardInput.Close()
        if(-not $process.WaitForExit(60000)) { $process.Kill(); throw 'BAT timed out.' }
        $process.WaitForExit()
        [pscustomobject]@{Code=$process.ExitCode;Text=$outTask.Result+$errTask.Result}
    } finally {$process.Dispose()}
}
function Snapshot([string]$Path) {
    (@(Get-SafeFiles $Path $null -Recurse | ForEach-Object { (Get-RelativeName $Path $_.FullName) + '|' + (Get-FileHash -LiteralPath $_.FullName).Hash }) -join "`n")
}
function Run-Settings([string]$Name,$Options) {
    $entry=$catalog | Where-Object Name -eq $Name
    $dir=Split-Path (Join-Path $project $entry.Path)
    $optionsPath=Join-Path $fixtures 'settings.json'
    $Options | ConvertTo-Json | Set-Content -LiteralPath $optionsPath -Encoding UTF8
    $exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $result=Invoke-Native $exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $project '_shared\ToolRunner.ps1'),'-Tool',$Name,'-ToolDir',$dir,'-Defaults','-SettingsFile',$optionsPath) 60000
    $result
}
try {
    $ffmpeg=Require-Dependency 'ffmpeg'; $magick=Require-Dependency 'magick'; $gs=Require-Dependency 'ghostscript'
    [void](Invoke-Checked $magick @('-size','128x96','xc:white','-fill','red','-draw','rectangle 20,20 90,70','image.png'))
    [void](Invoke-Checked $magick @('image.png','image.jpg'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','color=c=blue:s=160x120:r=24:d=1','-f','lavfi','-i','sine=frequency=440:duration=1','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac','-shortest','video.mp4'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-i','video.mp4','-an','-c:v','copy','silent.mp4'))
    [void](Invoke-Checked $ffmpeg @('-v','error','-nostdin','-n','-f','lavfi','-i','sine=frequency=220:duration=1','audio.wav'))
    [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=document.pdf','-c','/Helvetica findfont 16 scalefont setfont 72 720 moveto (Tools Bat test) show showpage'))
    Copy-Item -LiteralPath (Join-Path $fixtures 'document.pdf') -Destination (Join-Path $fixtures 'document2.pdf')
    $arabic=-join ([char[]]@(0x0639,0x064A,0x0646,0x0629))
    $special=$arabic + ' ! %TB_UNDEFINED% & ^ (test) [1]'
    foreach($entry in $catalog) {
        $bat=Join-Path $project $entry.Path; $dir=Split-Path $bat
        Ensure-Directory $dir; Ensure-Directory (Join-Path $dir 'Input'); Ensure-Directory (Join-Path $dir 'Output')
        Copy-Item -LiteralPath (Join-Path $sourceRoot $entry.Path) -Destination $bat
        if($entry.Dependency -eq 'magick') {
            Copy-Item -LiteralPath (Join-Path $fixtures 'image.png') -Destination (Join-Path $dir ('Input\'+$special+'.png'))
            if($entry.Name -eq 'Image Watermark') { Ensure-Directory (Join-Path $dir 'Watermark'); Copy-Item -LiteralPath (Join-Path $fixtures 'image.png') -Destination (Join-Path $dir 'Watermark\logo.png') }
        } elseif($entry.Dependency -eq 'ghostscript') {
            Copy-Item -LiteralPath (Join-Path $fixtures 'document.pdf') -Destination (Join-Path $dir ('Input\001 '+$special+'.pdf'))
            if($entry.Name -eq 'Merge PDF') {Copy-Item -LiteralPath (Join-Path $fixtures 'document.pdf') -Destination (Join-Path $dir 'Input\002.pdf')}
        } elseif($entry.Name -eq 'Audio Converter') {
            Copy-Item -LiteralPath (Join-Path $fixtures 'audio.wav') -Destination (Join-Path $dir ('Input\'+$special+'.wav'))
        } elseif($entry.Dependency -in @('ffmpeg','ffprobe')) {
            Copy-Item -LiteralPath (Join-Path $fixtures 'video.mp4') -Destination (Join-Path $dir ('Input\'+$special+'.mp4'))
            if($entry.Name -in @('Replace Audio','Merge Audio')) { Copy-Item -LiteralPath (Join-Path $fixtures 'audio.wav') -Destination (Join-Path $dir ('Input\'+$special+'.wav')) }
        } else {
            Ensure-Directory (Join-Path $dir 'Input\nested')
            [IO.File]::WriteAllText((Join-Path $dir ('Input\'+$special+'.txt')),'same bytes')
            [IO.File]::WriteAllText((Join-Path $dir 'Input\nested\copy.txt'),'same bytes')
            [IO.File]::WriteAllText((Join-Path $dir 'Input\hidden.txt'),'hidden')
            (Get-Item -LiteralPath (Join-Path $dir 'Input\hidden.txt')).Attributes='Hidden'
        }
        if($entry.Name -eq 'ZIP Extract') {
            $zipFiles=@(Get-SafeFiles (Join-Path $dir 'Input') @('.txt') -Recurse)
            Zip-Create $zipFiles (Join-Path $dir 'Input') (Join-Path $dir 'Input\sample.zip')
        }
        try {
            $before=Snapshot (Join-Path $dir 'Input')
            $run=Run-Bat $bat
            [IO.File]::WriteAllText((Join-Path $fixtures ($entry.Name+'.log')),$run.Text)
            Assert ($run.Code -eq 0) ('Exit '+$run.Code+': '+$run.Text)
            Assert ($run.Text -match 'Successful: [1-9][0-9]*') 'The first run skipped processing instead of producing a fresh result.'
            Assert (@(Get-SafeFiles (Join-Path $dir 'Output') $null -Recurse).Count -gt 0) 'No output.'
            Assert ((Snapshot (Join-Path $dir 'Input')) -eq $before) 'Source input changed.'
            $output=Snapshot (Join-Path $dir 'Output')
            $again=Run-Bat $bat
            Assert ($again.Code -eq 0) ('Repeat failed: '+$again.Text)
            Assert ((Snapshot (Join-Path $dir 'Output')) -eq $output) 'Existing output changed on repeat.'
            Record $entry.Name $true 'BAT executed from another working directory; moved special/Arabic filenames; output produced; inputs preserved; repeat skipped existing output.'
        } catch { Record $entry.Name $false $_.Exception.Message }
        if($entry.Path -like 'VID\Video - Audio\*') {
            # The seven original BATs intentionally share Output and result names.
            # Preserve each job's results separately before testing the next BAT.
            $from=[IO.Path]::GetFullPath((Join-Path $dir 'Output'))
            $to=[IO.Path]::GetFullPath((Join-Path $fixtures ('tool-output\'+$entry.Name)))
            $boundary=[IO.Path]::GetFullPath($runRoot).TrimEnd('\')+'\'
            if(-not $from.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase) -or -not $to.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe test-output move.'}
            Ensure-Directory (Split-Path $to)
            [IO.Directory]::Move($from,$to)
            Ensure-Directory $from
        }
    }
    foreach($name in @('Image Crop','Image Resize','Image Enhance')) {
        try {
            $entry=$catalog | Where-Object Name -eq $name
            $out=@(Get-SafeFiles (Join-Path (Split-Path (Join-Path $project $entry.Path)) 'Output') @('.png'))[0]
            Copy-Item -LiteralPath $out.FullName -Destination (Join-Path $fixtures 'inspect.png') -Force
            $dimensions=(Invoke-Checked $magick @('identify','-format','%wx%h','inspect.png')).Trim()
            $expected=switch($name){'Image Crop'{'96x96'};'Image Resize'{'128x96'};'Image Enhance'{'256x192'}}
            Assert ($dimensions -eq $expected) "Unexpected dimensions: $dimensions"
            Record ($name+' dimensions') $true $dimensions
        }catch{Record ($name+' dimensions') $false $_.Exception.Message}
    }
    try {
        $hashBat=Join-Path $project 'UTI\File Hashes\File Hashes.bat'
        $run=Run-Bat $hashBat '--verify'; Assert ($run.Code -eq 0) $run.Text
        [IO.File]::AppendAllText((Join-Path $project 'UTI\File Hashes\Input\nested\copy.txt'),'tamper')
        $run=Run-Bat $hashBat '--verify'; Assert ($run.Code -eq 1) 'Tampering was not detected.'
        Record 'Hash verify/tamper' $true 'Verified matching files and detected modified bytes.'
    } catch {Record 'Hash verify/tamper' $false $_.Exception.Message}
    try {
        $rows=@(Import-Csv -LiteralPath (Join-Path $project 'UTI\Duplicate Finder\Output\duplicates.csv'))
        Assert ($rows.Count -eq 2) 'Expected two duplicate members.'
        Record 'Duplicate contents' $true 'Only two files with equal SHA-256 reported.'
    } catch {Record 'Duplicate contents' $false $_.Exception.Message}
    foreach($entry in $catalog) {
        try {
            $run=Run-Bat (Join-Path $project $entry.Path) '--check' '' $true
            Assert ($run.Code -eq $(if($entry.Dependency){if($entry.Original){3}else{2}}else{0})) ('Unexpected missing-dependency code: '+$run.Code+' '+$run.Text)
            Record ($entry.Name+' missing dependency') $true 'No download or prompt; useful nonzero code when required.'
        }catch{Record ($entry.Name+' missing dependency') $false $_.Exception.Message}
    }
    foreach($arguments in @('--check','--check')) {
        try {$run=Run-Bat (Join-Path $project 'START_HERE.bat') $arguments; Assert ($run.Code -eq 0) $run.Text; Record 'START_HERE repeat' $true 'Dependency check passed, no download.'}
        catch{Record 'START_HERE repeat' $false $_.Exception.Message}
    }
    try {
        $run=Run-Bat (Join-Path $project 'START_HERE.bat') '' "n`nn`nn`nn`n" $true
        Assert ($run.Code -eq 3) $run.Text
        Assert (-not (Test-Path -LiteralPath (Join-Path $project '_downloads'))) 'Declining downloads created download files.'
        Record 'START_HERE decline all' $true 'All three missing packages declined; nothing downloaded.'
    }catch{Record 'START_HERE decline all' $false $_.Exception.Message}
    if(-not $Quick) {
        try {
            # The custom dimension must reject a shell operator BEFORE expansion.
            $run=Run-Bat (Join-Path $project 'IMG\Image Resize\Image Resize.bat') '' "4`n100&echo INJECTED`n100`nY`n"
            Assert ($run.Code -eq 2 -and $run.Text -notmatch '(?m)^INJECTED') $run.Text
            Record 'Batch input validation' $true 'Rejected invalid width before cmd expansion.'
        }catch{Record 'Batch input validation' $false $_.Exception.Message}
        try {
            # Real public DNS/connect attempt, no program is downloaded.
            $target=Join-Path $fixtures 'network-metadata.tmp'
            try {Receive-HTTPS 'https://www.gyan.dev/ffmpeg/builds/packages/nonexistent-toolsbat-test.sha256' $target; throw 'Unexpected network success.'}
            catch {Assert ($_.Exception.Message -ne 'Unexpected network success.') 'Expected network/HTTP failure.'}
            Record 'Real network failure' $true 'Network/HTTP failure raised a handled error.'
        }catch{Record 'Real network failure' $false $_.Exception.Message}
    }
    # Fixture-only download/installation pipeline; never downloads software.
    $package=[pscustomobject]@{Id='fixture';Folder='fixture';Version='1.0';Name='fixture';Url='https://www.gyan.dev/fixture.zip';HashUrl='';SHA256=('0'*64);ApproxMB=1;Kind='zip'}
    $fixtureZip=Join-Path $fixtures 'safe.zip'
    Zip-Create @((Get-Item -LiteralPath (Join-Path $fixtures 'image.png'))) $fixtures $fixtureZip
    foreach($case in @('partial','offline')) {
        try {
            $testRoot=Join-Path $runRoot ('download-'+$case); Ensure-Directory $testRoot
            $failedAsExpected=$false
            try {
                if($case -eq 'partial'){Install-PortablePackage $package $testRoot {param($url,$path) [IO.File]::WriteAllText($path,'partial bytes')}}
                else{Install-PortablePackage $package $testRoot {param($url,$path) throw 'Simulated offline connection'}}
            } catch {$failedAsExpected=$true}
            Assert $failedAsExpected 'Bad download accepted.'
            Assert (-not (Test-Path -LiteralPath (Join-Path $testRoot '_bin\fixture'))) 'Invalid package installed.'
            Assert (@(Get-ChildItem -LiteralPath (Join-Path $testRoot '_downloads') -Force).Count -eq 0) 'Partial data not cleaned.'
            Record ('Download '+$case) $true 'Rejected before extraction; own partial files cleaned.'
        }catch{Record ('Download '+$case) $false $_.Exception.Message}
    }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $evil=Join-Path $fixtures 'traversal.zip'
        $stream=[IO.File]::Open($evil,[IO.FileMode]::CreateNew)
        $zip=New-Object IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Create,$false)
        $entry=$zip.CreateEntry('../escape.txt'); $writer=New-Object IO.StreamWriter($entry.Open()); $writer.Write('bad'); $writer.Dispose(); $zip.Dispose(); $stream.Dispose()
        $rejected=$false; try{Zip-Extract $evil (Join-Path $fixtures 'extract-test')}catch{$rejected=$true}
        Assert $rejected 'Traversal accepted.'
        Assert (-not (Test-Path -LiteralPath (Join-Path $fixtures 'escape.txt'))) 'Traversal wrote outside extraction root.'
        Record 'ZIP traversal' $true 'Rejected before writing an archive member.'
    }catch{Record 'ZIP traversal' $false $_.Exception.Message}
    if(-not $Quick) { . (Join-Path $PSScriptRoot 'Extended-Tests.ps1') }
} catch { Record 'Test infrastructure' $false $_.Exception.Message }
finally {
    $report=Join-Path $PSScriptRoot 'results.json'
    [pscustomobject]@{DateUTC=[DateTime]::UtcNow.ToString('o');Windows=[Environment]::OSVersion.Version.ToString();PowerShell=$PSVersionTable.PSVersion.ToString();Sandbox=$runRoot;Results=@($script:Results.ToArray())} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $report -Encoding UTF8
    Write-Host ('Results: '+$report)
    Write-Host ('Sandbox preserved: '+$runRoot)
}
if(@($script:Results | Where-Object {-not $_.Passed}).Count){exit 1}
exit 0
