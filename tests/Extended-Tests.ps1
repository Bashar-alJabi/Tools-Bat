# Executed by Run-Tests.ps1 in the same scope, using its private test sandbox.
function Test-Case([string]$Name,[string]$ToolName,[hashtable]$Options,[string[]]$Sources,[int]$Expected=0,[scriptblock]$Inspect={}) {
    try {
        $caseDir=Join-Path $runRoot ('cases\'+($Name -replace '[^a-zA-Z0-9-]','_'))
        Ensure-Directory (Join-Path $caseDir 'Input'); Ensure-Directory (Join-Path $caseDir 'Output')
        foreach($source in $Sources) {Copy-Item -LiteralPath (Join-Path $fixtures $source) -Destination (Join-Path $caseDir ('Input\'+$source))}
        if($ToolName -eq 'Image Watermark') {Ensure-Directory (Join-Path $caseDir 'Watermark'); Copy-Item -LiteralPath (Join-Path $fixtures 'black.png') -Destination (Join-Path $caseDir 'Watermark\logo.png')}
        $optionsFile=Join-Path $caseDir 'settings.json'
        $Options | ConvertTo-Json | Set-Content -LiteralPath $optionsFile -Encoding UTF8
        $runner=Join-Path $project '_shared\ToolRunner.ps1'
        $exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $response=Invoke-Native $exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',$runner,'-Tool',$ToolName,'-ToolDir',$caseDir,'-Defaults','-SettingsFile',$optionsFile) 60000
        [IO.File]::WriteAllText((Join-Path $caseDir 'run.log'),$response.Out+$response.Err)
        Assert ($response.Code -eq $Expected) ('Exit '+$response.Code+' '+$response.Out+$response.Err)
        if($Expected -eq 0) {Assert (@(Get-SafeFiles (Join-Path $caseDir 'Output') $null -Recurse).Count -gt 0) 'No output created.'}
        else {Assert (@(Get-SafeFiles (Join-Path $caseDir 'Output') $null -Recurse).Count -eq 0) 'Failed operation left a result.'}
        & $Inspect $caseDir
        Record $Name $true 'Expected result, exit code and output validated.'
    } catch {Record $Name $false $_.Exception.Message}
}
[void](Invoke-Checked $magick @('-size','32x32','xc:black','black.png'))
[void](Invoke-Checked $magick @('image.png','black.png','-delay','20','-loop','0','animated.gif'))
[IO.File]::WriteAllText((Join-Path $fixtures 'broken.png'),'not an image')
[IO.File]::WriteAllText((Join-Path $fixtures 'broken.mp4'),'not a video')
[IO.File]::WriteAllText((Join-Path $fixtures 'broken.pdf'),'not a PDF')
[IO.File]::WriteAllText((Join-Path $fixtures 'broken.zip'),'not a ZIP')
foreach($format in @('jpg','png','webp','tiff','bmp','gif','avif')) {Test-Case ('Image convert '+$format) 'Image Convert' @{FORMAT=$format;QUALITY='80'} @('image.jpg')}
foreach($format in @('mp3','wav','flac','m4a','opus')) {Test-Case ('Audio convert '+$format) 'Audio Converter' @{FORMAT=$format} @('audio.wav')}
foreach($preset in @('/screen','/ebook','/printer','/prepress','/default')) {Test-Case ('PDF preset '+$preset.TrimStart('/')) 'Compress PDF' @{PRESET=$preset} @('document.pdf')}
Test-Case 'Silent speed' 'Video Speed' @{SPEED='2'} @('silent.mp4') 0 {
    param($dir)
    $probe=Require-Dependency 'ffprobe'
    $output=@(Get-SafeFiles (Join-Path $dir 'Output') @('.mp4'))[0]
    $data=(Invoke-Checked $probe @('-v','error','-show_format','-show_streams','-of','json',$output.FullName)) | ConvertFrom-Json
    Assert (@($data.streams | Where-Object codec_type -eq 'audio').Count -eq 0) 'Silent input acquired audio.'
    Assert ([double]::Parse($data.format.duration,[Globalization.CultureInfo]::InvariantCulture) -le 0.6) 'Speed did not halve duration.'
}
Test-Case 'Silent fps' 'Video FPS Converter' @{FPS='60'} @('silent.mp4') 0 {
    param($dir)
    $probe=Require-Dependency 'ffprobe'; $output=@(Get-SafeFiles (Join-Path $dir 'Output') @('.mp4'))[0]
    $data=(Invoke-Checked $probe @('-v','error','-show_streams','-of','json',$output.FullName)) | ConvertFrom-Json
    Assert ($data.streams[0].r_frame_rate -eq '60/1') 'Wrong frame rate.'
}
Test-Case 'HEVC encode' 'Compress Video' @{MODE='H.265';CRF='26'} @('video.mp4')
Test-Case 'Custom image resize' 'Image Resize' @{WIDTH='100';HEIGHT='50'} @('image.png') 0 {
    param($dir)
    $output=@(Get-SafeFiles (Join-Path $dir 'Output') @('.png'))[0]; Copy-Item -LiteralPath $output.FullName -Destination (Join-Path $fixtures 'inspect.png') -Force
    Assert ((Invoke-Checked $magick @('identify','-format','%wx%h','inspect.png')).Trim() -eq '67x50') 'Aspect ratio or max bounds not respected.'
}
Test-Case 'Remove white transparency' 'Background Color Remover' @{COLOR='white';FUZZ='0%'} @('image.png') 0 {
    param($dir)
    $output=@(Get-SafeFiles (Join-Path $dir 'Output') @('.png'))[0]; Copy-Item -LiteralPath $output.FullName -Destination (Join-Path $fixtures 'inspect.png') -Force
    Assert ((Invoke-Checked $magick @('identify','-format','%[opaque]','inspect.png')).Trim() -eq 'False') 'White background is not transparent.'
}
Test-Case 'Watermark logo opacity 100' 'Image Watermark' @{TYPE='2';SIZE='100';OPACITY='100';GRAVITY1='center'} @('image.png') 0 {
    param($dir)
    $output=@(Get-SafeFiles (Join-Path $dir 'Output') @('.png'))[0]; Copy-Item -LiteralPath $output.FullName -Destination (Join-Path $fixtures 'inspect.png') -Force
    $pixel=(Invoke-Checked $magick @('identify','-format','%[pixel:p{64,48}]','inspect.png')).Trim()
    Assert ($pixel -match '\(0,0,0(?:,1)?\)') ('Opacity is not 100%: '+$pixel)
}
Test-Case 'Watermark nine positions' 'Image Watermark' @{TYPE='1';WATERMARK_TEXT='A "quote" & !';COUNT='9';SIZE='12';OPACITY='70';ROTATION='-8';GRAVITY1='northwest';GRAVITY2='north';GRAVITY3='northeast';GRAVITY4='west';GRAVITY5='center';GRAVITY6='east';GRAVITY7='southwest';GRAVITY8='south';GRAVITY9='southeast'} @('image.png')
Test-Case 'Animated GIF preserve' 'Image Convert' @{FORMAT='gif'} @('animated.gif') 0 {
    param($dir)
    Copy-Item -LiteralPath (Join-Path $dir 'Output\animated.gif') -Destination (Join-Path $fixtures 'inspect.gif') -Force
    Assert ((Invoke-Checked $magick @('identify','-format','%n','inspect.gif')).Trim() -eq '22') 'Animation frames were lost.'
}
Test-Case 'Animated to static rejected' 'Image Convert' @{FORMAT='png'} @('animated.gif') 1
foreach($case in @(@('Bad image','Image Resize','broken.png'),@('Bad video','Video Speed','broken.mp4'),@('Bad PDF','Compress PDF','broken.pdf'),@('Bad ZIP','ZIP Extract','broken.zip'))) {Test-Case $case[0] $case[1] @{} @($case[2]) 1}
Test-Case 'No audio extraction rejected' 'Extract Audio' @{} @('silent.mp4') 1
Test-Case 'Ambiguous replacement rejected' 'Replace Audio' @{} @('video.mp4','silent.mp4','audio.wav') 2
Test-Case 'Invalid quality rejected' 'Image Convert' @{QUALITY='101'} @('image.png') 2
Test-Case 'Same basename collision' 'Image Convert' @{FORMAT='png'} @('image.png','image.jpg') 0 {
    param($dir)
    Assert (@(Get-SafeFiles (Join-Path $dir 'Output') @('.png')).Count -eq 1) 'Collision created an unexpected result.'
}
Test-Case 'PDF merge pages' 'Merge PDF' @{} @('document.pdf','document2.pdf') 0 {
    param($dir)
    Copy-Item -LiteralPath (Join-Path $dir 'Output\merged.pdf') -Destination (Join-Path $fixtures 'inspect.pdf') -Force
    [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=png16m','-r36','-sOutputFile=merge-page-%d.png','inspect.pdf'))
    Assert (@(Get-ChildItem -LiteralPath $fixtures -Filter 'merge-page-*.png').Count -eq 2) 'Wrong merged PDF page count.'
}
function Run-Menu([string]$Path,[object[]]$Steps) {
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe'
    $info.Arguments='/d /v:off /s /c ""%TB_TEST_BAT%""'
    $info.WorkingDirectory=$fixtures; $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardInput=$true; $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $info.EnvironmentVariables['TB_TEST_BAT']=$Path; $info.EnvironmentVariables['TB_NO_PAUSE']='1'; $info.EnvironmentVariables['TB_LOCAL_ONLY']='0'
    $process=New-Object Diagnostics.Process; $process.StartInfo=$info
    try {
        [void]$process.Start(); $err=$process.StandardError.ReadToEndAsync()
        $builder=New-Object Text.StringBuilder; $buffer=New-Object char[] 1; $step=0; $lastPosition=0
        $watch=[Diagnostics.Stopwatch]::StartNew()
        while($true) {
            $read=$process.StandardOutput.ReadAsync($buffer,0,1)
            while(-not $read.Wait(200)) { if($watch.Elapsed.TotalSeconds -gt 45){$process.Kill(); throw 'Interactive menu timed out.'} }
            if($read.Result -eq 0){break}
            [void]$builder.Append($buffer[0])
            if($step -lt $Steps.Count -and $builder.ToString().Substring($lastPosition).Contains($Steps[$step].Prompt)) {
                $process.StandardInput.Write($Steps[$step].Reply); $process.StandardInput.Flush()
                $lastPosition=$builder.Length; $step++
            }
        }
        $process.StandardInput.Close(); $process.WaitForExit()
        Assert ($step -eq $Steps.Count) 'Not all prompts were reached.'
        [pscustomobject]@{Code=$process.ExitCode;Text=$builder.ToString()+$err.Result}
    }finally{$process.Dispose()}
}
foreach($menuCase in @(
    @{Name='Image Compression';Steps=@(@{Prompt='Select an option: ';Reply='2'},@{Prompt='Start compression? [Y/N]: ';Reply='Y'})},
    @{Name='Image Convert';Steps=@(@{Prompt='Select an option: ';Reply='2'},@{Prompt='Start conversion? [Y/N]: ';Reply='Y'})},
    @{Name='Image Resize';Steps=@(@{Prompt='Select an option: ';Reply='4'},@{Prompt='Enter maximum width: ';Reply="100`r`n"},@{Prompt='Enter maximum height: ';Reply="50`r`n"},@{Prompt='Start resizing? [Y/N]: ';Reply='Y'})},
    @{Name='Increase Volume';Steps=@(@{Prompt='Select an option: ';Reply='2'},@{Prompt='Continue? [Y/N]: ';Reply='Y'})},
    @{Name='Image Crop';Steps=@(@{Prompt='Enter choice: ';Reply="2`r`n"},@{Prompt='Start cropping? [Y/N]: ';Reply="Y`r`n"})},
    @{Name='Video FPS Converter';Steps=@(@{Prompt='Select FPS [1-5]: ';Reply="5`r`n"})}
)) {
    try {
        $entry=$catalog | Where-Object Name -eq $menuCase.Name
        $response=Run-Menu (Join-Path $project $entry.Path) $menuCase.Steps
        Assert ($response.Code -eq 0) ($response.Text+' Exit '+$response.Code)
        $mustContain=switch($menuCase.Name){'Image Compression'{'Quality          : 85'};'Image Convert'{'Output format: png'};'Image Resize'{'Maximum Width : 100'};'Increase Volume'{'+6 dB'};'Image Crop'{'Crop Ratio: 4:5'};'Video FPS Converter'{'Target FPS:     60'}}
        Assert ($response.Text.Contains($mustContain)) ('Menu chose the wrong option: '+$response.Text)
        Record ($menuCase.Name+' real menu') $true 'Selected nondefault option through cmd input; setting reached processing.'
    }catch{Record ($menuCase.Name+' real menu') $false $_.Exception.Message}
}
try {
    $testRoot=Join-Path $runRoot 'valid-download'; Ensure-Directory $testRoot
    $fixtureSource=Join-Path $fixtures 'package-source'; Ensure-Directory $fixtureSource
    $exeSource='public class ToolsBatFixture { public static void Main() { System.Console.WriteLine("fixture version 1.0"); } }'
    Add-Type -TypeDefinition $exeSource -Language CSharp -OutputAssembly (Join-Path $fixtureSource 'magick.exe') -OutputType ConsoleApplication
    [IO.File]::WriteAllText((Join-Path $fixtureSource 'LICENSE.txt'),'Safe test fixture; no third-party program was downloaded.')
    $packageZip=Join-Path $fixtures 'valid-package.zip'
    Zip-Create @(Get-SafeFiles $fixtureSource $null) $fixtureSource $packageZip
    $package=[pscustomobject]@{Id='magick';Folder='fixture';Version='1.0';Name='fixture';Url='https://www.gyan.dev/fixture.zip';HashUrl='';SHA256=(Get-FileHash -LiteralPath $packageZip).Hash;ApproxMB=1;Kind='zip'}
    Install-PortablePackage $package $testRoot {param($url,$path) Copy-Item -LiteralPath $packageZip -Destination $path}
    Assert (Test-Path -LiteralPath (Join-Path $testRoot '_bin\fixture\magick.exe')) 'Valid ZIP was not staged.'
    Assert (Test-Path -LiteralPath (Join-Path $testRoot '_bin\fixture\LICENSE.txt')) 'License files lost.'
    $before=Snapshot (Join-Path $testRoot '_bin')
    $preserved=$false;try{Install-PortablePackage $package $testRoot {throw 'Unexpected second fetch'}}catch{$preserved=$true}
    Assert ($preserved -and (Snapshot (Join-Path $testRoot '_bin')) -eq $before) 'Existing setup was not preserved.'
    Record 'Valid fixture download install/cache' $true 'Checksum, extraction, executable version, whole distribution, cache reuse and prior setup protection verified without downloading a program.'
    $sevenZip=Join-Path $fixtures 'valid-package.7z'
    $tar=Join-Path $env:SystemRoot 'System32\tar.exe'
    $previousWorkingDirectory=$script:NativeWorkingDirectory
    try {
        $script:NativeWorkingDirectory=$fixtureSource
        [void](Invoke-Checked $tar @('--format=7zip','-cf',$sevenZip,'magick.exe','LICENSE.txt'))
    } finally { $script:NativeWorkingDirectory=$previousWorkingDirectory }
    $package.Folder='fixture7z'; $package.Kind='7z'; $package.Url='https://www.gyan.dev/fixture.7z'; $package.SHA256=(Get-FileHash -LiteralPath $sevenZip).Hash
    Install-PortablePackage $package $testRoot {param($url,$path) Copy-Item -LiteralPath $sevenZip -Destination $path}
    Assert (Test-Path -LiteralPath (Join-Path $testRoot '_bin\fixture7z\magick.exe')) '7z package was not staged.'
    Record '7z fixture install' $true 'Windows tar created and extracted a verified local 7z fixture.'
    $package.Folder='installerfixture'; $package.Kind='installer'; $package.Url='https://www.gyan.dev/fixture.exe'; $package.SHA256=(Get-FileHash -LiteralPath $packageZip).Hash
    Install-PortablePackage $package $testRoot {param($url,$path) Copy-Item -LiteralPath $packageZip -Destination $path}
    Assert (-not (Test-Path -LiteralPath (Join-Path $testRoot '_bin\installerfixture'))) 'Installer was extracted/executed automatically.'
    Assert (Test-Path -LiteralPath (Join-Path $testRoot '_downloads\fixture.exe')) 'Verified installer fixture was not retained.'
    Record 'Installer download-only policy' $true 'Verified fixture saved without running or installing it.'
}catch{Record 'Valid fixture download install/cache' $false $_.Exception.Message}
try {
    $rejected=$false;try{Test-FreeSpace $fixtures ([long]::MaxValue)}catch{$rejected=$true}
    Assert $rejected 'Insufficient-space guard did not reject impossible allocation.'
    Record 'Insufficient space guard' $true 'Impossible allocation rejected without filling a disk.'
}catch{Record 'Insufficient space guard' $false $_.Exception.Message}
try {
    $zipRoot=Join-Path $runRoot 'zip-empty-hidden'; Ensure-Directory (Join-Path $zipRoot 'empty'); Ensure-Directory (Join-Path $zipRoot 'hidden-dir')
    [IO.File]::WriteAllText((Join-Path $zipRoot 'hidden-dir\hidden.txt'),'hidden bytes')
    (Get-Item -LiteralPath (Join-Path $zipRoot 'hidden-dir')).Attributes='Directory, Hidden'
    $zip=Join-Path $fixtures 'empty-hidden.zip'; Zip-Create @(Get-SafeFiles $zipRoot $null -Recurse) $zipRoot $zip
    $dest=Join-Path $fixtures 'empty-hidden-extracted'; Zip-Extract $zip $dest
    Assert ([IO.Directory]::Exists((Join-Path $dest 'empty'))) 'Empty directory lost.'
    Assert ([IO.File]::ReadAllText((Join-Path $dest 'hidden-dir\hidden.txt')) -eq 'hidden bytes') 'Hidden content lost.'
    Record 'ZIP empty/hidden tree' $true 'Empty directories and hidden content retained.'
}catch{Record 'ZIP empty/hidden tree' $false $_.Exception.Message}
foreach($entrySet in @(@('C:escape.txt'),@('CON.txt'),@('duplicate.txt','DUPLICATE.txt'),@('trailing.'))) {
    try {
        $archivePath=Join-Path $fixtures ([guid]::NewGuid().ToString('N')+'.zip')
        $archive=[IO.Compression.ZipFile]::Open($archivePath,[IO.Compression.ZipArchiveMode]::Create)
        foreach($name in $entrySet){$entry=$archive.CreateEntry($name); $writer=New-Object IO.StreamWriter($entry.Open()); $writer.Write('test'); $writer.Dispose()}
        $archive.Dispose()
        $rejected=$false;try{Zip-Extract $archivePath (Join-Path $fixtures ([guid]::NewGuid().ToString('N')))}catch{$rejected=$true}
        Assert $rejected 'Unsafe ZIP accepted.'
        Record ('ZIP rejects '+($entrySet -join ',')) $true 'Unsafe/ambiguous name rejected.'
    }catch{Record 'ZIP unsafe entry' $false $_.Exception.Message}
}
