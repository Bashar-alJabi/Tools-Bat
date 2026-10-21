param([Parameter(Mandatory=$true)][string]$LightArchive,[Parameter(Mandatory=$true)][string]$FullArchive)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\Archives.ps1')
$repository=$script:ProjectRoot
$work=Join-Path $PSScriptRoot ('_work\p-'+[guid]::NewGuid().ToString('N').Substring(0,8));Ensure-Directory $work
$results=New-Object 'Collections.Generic.List[object]'
$oldPath=$env:PATH;$oldLocal=$env:TB_LOCAL_ONLY
$savedEnvironment=@{}
foreach($item in @(Get-ChildItem Env:|Where-Object Name -match '^(MAGICK_|GS_|TESSDATA_|FONTCONFIG_|FFREPORT$)')){$savedEnvironment[$item.Name]=$item.Value;[Environment]::SetEnvironmentVariable($item.Name,$null,'Process')}
$env:PATH=$env:SystemRoot+'\System32;'+$env:SystemRoot;$env:TB_LOCAL_ONLY='1'
$ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
function Assert([bool]$Condition,[string]$Detail){if(-not $Condition){throw $Detail}}
function Record([string]$Name,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$true;Detail=$Detail});Write-Host ('PASS '+$Name)}
function Tree([string]$Path){(@(Get-SafeFiles $Path $null -Recurse|ForEach-Object{(Get-RelativeName $Path $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n")}
function Run-Bat([string]$Path,[string]$Argument,[string]$InputText=''){
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\cmd.exe';$info.Arguments='/d /v:off /s /c ""%TB_PORTABLE_BAT%" '+$Argument+'"'
    $info.EnvironmentVariables['TB_PORTABLE_BAT']=$Path;$info.EnvironmentVariables['TB_NO_PAUSE']='1'
    $info.WorkingDirectory=$work;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true;$info.RedirectStandardInput=$true
    $process=New-Object Diagnostics.Process;$process.StartInfo=$info
    try{
        [void]$process.Start();$out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write($InputText);$process.StandardInput.Close()
        if(-not $process.WaitForExit(120000)){$process.Kill();throw 'BAT timeout.'};$process.WaitForExit()
        [pscustomobject]@{Code=$process.ExitCode;Text=$out.Result+$err.Result}
    }finally{$process.Dispose()}
}
try{
    $light=Join-Path $work 'light';$full=Join-Path $work ('نقل & ! %X% [1]')
    foreach($edition in @(@{Name='light';Archive=$LightArchive;Folder=$light},@{Name='portable';Archive=$FullArchive;Folder=$full})){
        Zip-Extract ([IO.Path]::GetFullPath($edition.Archive)) $edition.Folder
        $manifest=Get-Content -LiteralPath (Join-Path $edition.Folder 'distribution-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
        foreach($entry in $manifest){Assert ((Get-FileHash -LiteralPath (Join-Path $edition.Folder $entry.Path)).Hash -ceq $entry.SHA256) ('Hash mismatch '+$entry.Path)}
        $catalog=Get-Content -LiteralPath (Join-Path $edition.Folder 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
        Assert ($catalog.Count -eq 100 -and @(Get-SafeFiles (Join-Path $edition.Folder 'Tools') @('.bat') -Recurse).Count -eq 100) 'Expected 100 tools.'
        foreach($tool in $catalog){Assert (Test-Path -LiteralPath ([IO.Path]::ChangeExtension((Join-Path $edition.Folder $tool.Path),'.md'))) 'Missing tool MD.'}
        foreach($file in (Get-SafeFiles $edition.Folder $null -Recurse)){
            $relative=Get-RelativeName $edition.Folder $file.FullName
            Assert ($relative -notmatch '^(Development|\.git|System\\Downloads)\\' -and $relative -notmatch '^Tools\\.*\\(Input|Output|Watermark)\\') ('Leaked development/personal file '+$relative)
        }
        Record ($edition.Name+' ZIP integrity/layout') ($manifest.Count.ToString()+' file hashes verified; 100 BAT+MD; no development, Git, downloads or user inputs/outputs.')
    }
    Assert (@(Get-SafeFiles (Join-Path $light 'System\Bin') $null -Recurse).Count -eq 0) 'Light ZIP contains programs.'
    $check=Run-Bat (Join-Path $light 'START_HERE.bat') '--check'
    Assert ($check.Code -eq 3 -and ([regex]::Matches($check.Text,'\[MISSING\] (ffmpeg|ffprobe|magick|ghostscript|qpdf|tesseract)\b')).Count -eq 6) ('Light isolation did not report missing dependencies: '+$check.Text)
    Record 'Light ZIP honest missing dependencies' 'All six programs missing with system discovery disabled; START_HERE exit 3, no silent installed fallback.'
    $run=Run-Bat (Join-Path $light 'BUILD_DISTRIBUTION.bat') '--portable'
    Assert ($run.Code -eq 2 -and $run.Text -match 'requires a compatible LOCAL') ('Incomplete full build was not refused: '+$run.Text)
    Record 'Incomplete portable build refused' 'Full edition cannot be built from an empty Bin and cannot use installed programs to pretend completeness.'
    $inventory=Join-Path $light 'Tools\UTI\File Inventory';[IO.File]::WriteAllText((Join-Path $inventory 'Input\عربي & [1].txt'),'portable sample')
    $run=Run-Bat (Join-Path $inventory 'File Inventory.bat') '--defaults';Assert ($run.Code -eq 0 -and @(Get-SafeFiles (Join-Path $inventory 'Output') $null -Recurse).Count -gt 0) $run.Text
    Record 'Light native Windows tool' 'File Inventory actually runs without external programs after extraction.'
    $script:ProjectRoot=$full;$script:NativeWorkingDirectory=$work
    foreach($name in @('ffmpeg','ffprobe','magick','ghostscript','qpdf','tesseract')){
        $dep=Get-Dependency $name -LocalOnly
        Assert ($null -ne $dep -and $dep.Local -and $dep.Path.StartsWith($full+'\',[StringComparison]::OrdinalIgnoreCase)) ('Non-local '+$name)
        Record ($name+' extracted local version/capability') $dep.Version
    }
    . (Join-Path $full 'System\Shared\OCR.ps1');$configuration=Get-OCRConfiguration
    Test-OCRLanguages $configuration 'ara+eng'
    $packages=Get-Content -LiteralPath (Join-Path $full 'System\Shared\packages.json') -Raw|ConvertFrom-Json
    foreach($code in @('ara','eng','osd')){
        $package=$packages|Where-Object Id -eq ('tessdata-'+$code)
        Assert ((Get-FileHash -LiteralPath (Join-Path $configuration.Data ($code+'.traineddata'))).Hash -ieq $package.SHA256) ('Model hash '+$code)
    }
    Assert (Test-Path -LiteralPath (Join-Path $configuration.Data 'pdf.ttf')) 'Missing OCR PDF font.'
    Record 'OCR baseline resources' 'ara+eng initialized; all three model SHA-256 match pinned packages; pdf.ttf present.'
    $binBefore=Tree (Join-Path $full 'System\Bin')
    foreach($argument in @('--check','--check','')){
        $run=Run-Bat (Join-Path $full 'START_HERE.bat') $argument "`r`nN`r`n"
        Assert ($run.Code -eq 0 -and ([regex]::Matches($run.Text,'project local')).Count -ge 6 -and $run.Text -notmatch '\[MISSING|Download this package\?|Download this optional model\?') ('Full setup failed: '+$run.Text)
        Record ('Full START_HERE '+$(if($argument){$argument}else{'interactive with optional language skipped'})) 'All six executable paths local, ara/eng/osd available; no download offer/consent; Bin hashes unchanged checked below.'
    }
    Assert ((Tree (Join-Path $full 'System\Bin')) -ceq $binBefore -and -not (Test-Path -LiteralPath (Join-Path $full 'System\Downloads'))) 'Setup changed ready runtimes or created downloads.'
    Record 'Idempotent setup without downloading' 'Repeated --check and interactive run preserved every Bin byte; no Downloads folder created. No network firewall was installed.'
    $gs=Require-Dependency ghostscript;$magick=Require-Dependency magick;$qpdf=Require-Dependency qpdf
    # Like real tools, native processing uses an owned scratch folder INSIDE the
    # moved project. The BAT itself above still starts in an unrelated directory.
    $script:NativeWorkingDirectory=New-WorkDirectory $full
    [void](Invoke-Checked $gs @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=local.pdf','-c','/Helvetica findfont 20 scalefont setfont 72 720 moveto (LOCAL PORTABLE PDF) show showpage'))
    [void](Invoke-Checked $magick @('-density','72','local.pdf[0]','-format','%wx%h','info:'))
    [void](Invoke-Checked $qpdf @('--check','local.pdf'))
    Record 'Local Ghostscript PDF/font and ImageMagick PDF delegate' 'Created a real PDF with local GS fonts, rendered page through ImageMagick local GS delegate and checked its structure using extracted qpdf.'
    . (Join-Path $full 'System\Shared\PDF.ps1');$script:QPDF=$qpdf
    # The existing helper sends private qpdf arguments on stdin, never argv/disk.
    $secret='test-only-'+[guid]::NewGuid().ToString('N')
    $job=@{inputFile='local.pdf';outputFile='locked.pdf';encrypt=@{userPassword=$secret;ownerPassword=$secret;'256bit'=@{}}}
    $result=Invoke-QPDFJob $qpdf $job
    Assert ($result.Code -eq 0) 'qpdf local encryption failed.'
    $wrong=Invoke-Native $qpdf @('@-') 30000 "locked.pdf`n--password=wrong`n--check`n"
    Assert ($wrong.Code -ne 0) 'qpdf accepted wrong password.'
    $right=Invoke-QPDFJob $qpdf @{inputFile='locked.pdf';password=$secret;outputFile='unlocked.pdf';decrypt=''}
    Assert ($right.Code -eq 0) 'qpdf did not decrypt with correct password.'
    [void](Invoke-Checked $qpdf @('--check','unlocked.pdf'));$secret=$null;$job=$null
    Record 'Extracted qpdf AES-256 and decryption' 'Private stdin encryption; wrong password refused; right password produced a structurally valid PDF. No passwords recorded.'
}catch{$results.Add([pscustomobject]@{Test='Portable release validation';Passed=$false;Detail=($_.Exception.Message+' | '+$_.ScriptStackTrace).Replace($repository,'<PROJECT_ROOT>')});Write-Host ('FAIL '+$_.Exception.Message);Write-Host $_.ScriptStackTrace}
finally{
    $env:PATH=$oldPath;$env:TB_LOCAL_ONLY=$oldLocal
    foreach($key in $savedEnvironment.Keys){[Environment]::SetEnvironmentVariable($key,$savedEnvironment[$key],'Process')}
    $report=[pscustomobject]@{DateUTC=[datetime]::UtcNow.ToString('o');Sandbox=$work.Replace($repository,'<PROJECT_ROOT>');FullRoot=$full.Replace($repository,'<PROJECT_ROOT>');LightArchive=$LightArchive.Replace($repository,'<PROJECT_ROOT>');FullArchive=$FullArchive.Replace($repository,'<PROJECT_ROOT>');Isolation='Child process PATH=Windows/System32;Windows, TB_LOCAL_ONLY=1, program resource variables cleared. Built-in Windows DLLs/fonts/.NET remain; no other PC/VM tested.';Results=$results.ToArray()}
    $report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'portable-release-results.json') -Encoding UTF8
}
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
