# Shared Windows PowerShell 5.1 runtime. No global environment changes.
if ($PSVersionTable.PSVersion.Major -eq 5) {
    # A PowerShell 7 parent can pass incompatible module directories to cmd/5.1.
    # Limit this process to Windows' built-in modules; never persist this change.
    $env:PSModulePath = (Join-Path $PSHOME 'Modules') + ';' + (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules')
}
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
    [Console]::InputEncoding = New-Object Text.UTF8Encoding($false)
} catch { } # Some hosts do not expose console handles; filesystem APIs stay Unicode.
$script:ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function ConvertTo-NativeArgument([string]$Value) {
    # CommandLineToArgvW / Microsoft CRT quoting; never invoke cmd.exe.
    '"' + [regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}
function Invoke-Native([string]$Executable, [string[]]$Arguments, [int]$Timeout = 0, [string]$InputText = '') {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $info.UseShellExecute = $false
    if ([IO.Path]::GetFileName($Executable) -ieq 'powershell.exe') {
        $info.EnvironmentVariables['PSModulePath'] = (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules') + ';' + (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules')
    }
    $executableName=[IO.Path]::GetFileName($Executable)
    $executableDirectory=[IO.Path]::GetDirectoryName($Executable)
    if($executableName -ieq 'magick.exe') {
        $info.EnvironmentVariables['MAGICK_HOME']=$executableDirectory
        $info.EnvironmentVariables['MAGICK_CONFIGURE_PATH']=$executableDirectory
        $coders=Join-Path $executableDirectory 'modules\coders'
        if(Test-Path -LiteralPath $coders){$info.EnvironmentVariables['MAGICK_CODER_MODULE_PATH']=$coders}
    }
    if($executableName -imatch '^gswin(32|64)c\.exe$') {
        $info.EnvironmentVariables['GS_OPTIONS']=''
        $gsHome=if([IO.Path]::GetFileName($executableDirectory) -ieq 'bin'){[IO.Path]::GetDirectoryName($executableDirectory)}else{$executableDirectory}
        $gsLibraries=@('%rom%Resource/Init/','%rom%lib/')
        foreach($relative in @('lib','Resource\Init','Resource\Font','fonts','iccprofiles')){
            $library=Join-Path $gsHome $relative
            if(Test-Path -LiteralPath $library){$gsLibraries+=$library}
        }
        $info.EnvironmentVariables['GS_LIB']=$gsLibraries -join ';'
    }
    if (Get-Variable NativeWorkingDirectory -Scope Script -ErrorAction SilentlyContinue) { $info.WorkingDirectory = $script:NativeWorkingDirectory }
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.RedirectStandardInput = $true
    $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        if ($InputText) {
            # .NET Framework (PowerShell 5.1) has no StandardInputEncoding property.
            $inputBytes=(New-Object Text.UTF8Encoding($false)).GetBytes($InputText)
            try { $process.StandardInput.BaseStream.Write($inputBytes,0,$inputBytes.Length); $process.StandardInput.BaseStream.Flush() }
            finally { [Array]::Clear($inputBytes,0,$inputBytes.Length) }
        }
        $process.StandardInput.Close()
        if ($Timeout -gt 0 -and -not $process.WaitForExit($Timeout)) {
            $process.Kill()
            $process.WaitForExit()
            throw "Program timed out: $Executable"
        }
        if ($Timeout -eq 0 -and (Get-Variable ReportNativeProgress -Scope Script -ErrorAction SilentlyContinue)) {
            $elapsed=[Diagnostics.Stopwatch]::StartNew()
            while(-not $process.WaitForExit(1000)) {
                Write-Progress -Activity ('Running ' + [IO.Path]::GetFileNameWithoutExtension($Executable)) -Status ('Elapsed: ' + $elapsed.Elapsed.ToString('hh\:mm\:ss'))
            }
            Write-Progress -Activity ('Running ' + [IO.Path]::GetFileNameWithoutExtension($Executable)) -Completed
        }
        $process.WaitForExit()
        [pscustomobject]@{ Code = $process.ExitCode; Out = $outTask.Result; Err = $errTask.Result }
    } finally { $process.Dispose() }
}
function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
    $result = Invoke-Native $Executable $Arguments
    if ($result.Code -ne 0) { throw ($result.Err + $result.Out).Trim() }
    $result.Out
}
function Get-Dependency([ValidateSet('ffmpeg','ffprobe','magick','ghostscript','qpdf','tesseract')][string]$Name, [switch]$LocalOnly) {
    $candidates = New-Object 'Collections.Generic.List[string]'
    $names = @($Name + '.exe')
    if ($Name -eq 'ghostscript') { $names = @('gswin64c.exe','gswin32c.exe') }
    $folder = if ($Name -eq 'ffprobe') { 'ffmpeg' } elseif ($Name -eq 'magick') { 'imagemagick' } else { $Name }
    $local = Join-Path $script:ProjectRoot ('System\Bin\' + $folder)
    if (Test-Path -LiteralPath $local) {
        foreach ($exeName in $names) {
            Get-ChildItem -LiteralPath $local -Filter $exeName -File -Recurse | Sort-Object FullName | ForEach-Object { $candidates.Add($_.FullName) }
        }
    }
    if (-not $LocalOnly -and $env:TB_LOCAL_ONLY -ne '1') {
        # Search installed applications as well as PATH. Never persist their paths.
        foreach ($exeName in $names) {
            Get-Command $exeName -CommandType Application -All -ErrorAction SilentlyContinue | ForEach-Object { $candidates.Add($_.Source) }
        }
        $programRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
        foreach ($programRoot in $programRoots) {
            if ($Name -eq 'magick') {
                Get-ChildItem -LiteralPath $programRoot -Directory -Filter 'ImageMagick*' | Sort-Object Name -Descending | ForEach-Object { $candidates.Add((Join-Path $_.FullName 'magick.exe')) }
            } elseif ($Name -eq 'ghostscript') {
                $gsRoot = Join-Path $programRoot 'gs'
                if (Test-Path -LiteralPath $gsRoot) {
                    foreach ($exeName in $names) { Get-ChildItem -LiteralPath $gsRoot -Filter $exeName -File -Recurse | Sort-Object FullName -Descending | ForEach-Object { $candidates.Add($_.FullName) } }
                }
            } elseif ($Name -in @('qpdf','tesseract')) {
                $pattern=if($Name -eq 'tesseract'){'Tesseract*'}else{'qpdf*'}
                foreach($directory in (Get-ChildItem -LiteralPath $programRoot -Directory -Filter $pattern)) {
                    foreach($file in (Get-SafeFiles $directory.FullName @('.exe') -Recurse | Where-Object Name -eq ($Name+'.exe'))){$candidates.Add($file.FullName)}
                }
            }
        }
    }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try {
            $versionArgs = if ($Name -in @('ghostscript','qpdf','tesseract')) { @('--version') } else { @('-version') }
            $version = Invoke-Native $candidate $versionArgs 15000
            $text = $version.Out + $version.Err
            $valid = $version.Code -eq 0
            switch ($Name) {
                'magick' { $valid = $valid -and $text -match 'ImageMagick 7\.' }
                'ffmpeg' { $valid = $valid -and $text -match 'ffmpeg version (?:n)?(\d+)' -and [int]$Matches[1] -ge 6 }
                'ffprobe' { $valid = $valid -and $text -match 'ffprobe version (?:n)?(\d+)' -and [int]$Matches[1] -ge 6 }
                'ghostscript' { $valid = $valid -and $text.Trim() -match '^\d+\.\d+' -and [version]$text.Trim() -ge [version]'10.05.0' }
                'qpdf' { $valid = $valid -and $text -match 'qpdf version (\d+)' -and [int]$Matches[1] -ge 12 }
                'tesseract' { $valid = $valid -and $text -match 'tesseract (?:v)?(\d+)' -and [int]$Matches[1] -ge 5 }
            }
            if ($valid -and $Name -eq 'ffmpeg') {
                $capabilities=Invoke-Native $candidate @('-hide_banner','-encoders') 15000
                $valid=$capabilities.Code -eq 0 -and $capabilities.Out -match '\blibx264\b' -and $capabilities.Out -match '\blibmp3lame\b' -and $capabilities.Out -match '\baac\b'
            }
            if ($valid -and $Name -eq 'magick') {
                $capabilities=Invoke-Native $candidate @('-list','format') 15000
                $valid=$capabilities.Code -eq 0 -and $capabilities.Out -match '(?m)^\s*PNG\*?\s+PNG\s+rw' -and $capabilities.Out -match '(?m)^\s*JPEG\*?\s+JPEG\s+rw'
            }
            if ($valid -and $Name -eq 'ghostscript') {
                $capabilities=Invoke-Native $candidate @('-h') 15000
                $valid=$capabilities.Code -eq 0 -and $capabilities.Out -match '\bpdfwrite\b'
            }
            if ($valid) { return [pscustomobject]@{ Name=$Name; Path=$candidate; Version=($text -split '[\r\n]')[0]; Local=$candidate.StartsWith($local + '\',[StringComparison]::OrdinalIgnoreCase) } }
        } catch { Write-Verbose "Rejected $candidate : $_" }
    }
    return $null
}
function Require-Dependency([string]$Name) {
    $dependency = Get-Dependency $Name
    if (-not $dependency) { throw "Missing or incompatible $Name. Run START_HERE.bat. No download was started." }
    $dependency.Path
}
function Ensure-Directory([string]$Path) {
    if (-not [IO.Directory]::Exists($Path)) { [void][IO.Directory]::CreateDirectory($Path) }
    if ((Get-Item -LiteralPath $Path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked folders are not accepted: $Path" }
}
function New-WorkDirectory([string]$Parent) {
    Ensure-Directory $Parent
    $path = Join-Path $Parent ('.toolsbat-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($path)
    $path
}
function Remove-WorkDirectory([string]$Path, [string]$Parent) {
    # Only a private, newly created directory, with an explicitly checked parent.
    $full = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    if (-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($full) -notmatch '^\.toolsbat-[a-f0-9]{32}$') { throw 'Unsafe cleanup target.' }
    if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
}
function Get-SafeFiles([string]$Directory, [string[]]$Extensions, [switch]$Recurse) {
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return }
    foreach ($entry in (Get-ChildItem -LiteralPath $Directory -Force | Sort-Object Name)) {
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        if ($entry.Name -eq '.gitkeep') { continue } # Preserve empty folders in Git without processing their placeholder.
        if ($entry.PSIsContainer) { if ($Recurse) { Get-SafeFiles $entry.FullName $Extensions -Recurse }; continue }
        if (-not $Extensions -or $Extensions -contains $entry.Extension.ToLowerInvariant()) { $entry }
    }
}
function Publish-File([string]$Source, [string]$Destination) {
    if (-not [IO.File]::Exists($Source) -or (Get-Item -LiteralPath $Source).Length -eq 0) { throw 'The program did not create a nonempty output.' }
    # File.Move has no overwrite option on .NET Framework. This also closes races.
    [IO.File]::Move($Source,$Destination)
}
function Test-FreeSpace([string]$Path, [long]$Required) {
    $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($Path))
    if ($root -match '^[A-Za-z]:\\$') {
        $drive = New-Object IO.DriveInfo($root)
        if ($drive.AvailableFreeSpace -lt $Required) { throw "Insufficient disk space. At least $Required bytes are needed." }
    }
}
function Get-RelativeName([string]$Root,[string]$Path) { $Path.Substring($Root.TrimEnd('\').Length + 1) }
function Get-SafeDirectories([string]$Directory) {
    foreach($entry in (Get-ChildItem -LiteralPath $Directory -Directory -Force | Sort-Object Name)) {
        if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){continue}
        $entry
        Get-SafeDirectories $entry.FullName
    }
}

# Small I/O helpers used by the independent scripts inside each new tool folder.
# Processing commands and menus belong to that tool, not a central dispatcher.
function Show-LocalTool([string]$Name,[string]$Folder,[string]$Mode,[string]$Dependency,[string]$Description) {
    if ($Mode -eq 'Help') { Write-Host $Description; Write-Host 'Put files in Input. Results go to Output. See the MD beside this BAT. --defaults / --check / --help'; exit 0 }
    if ($Dependency) { $script:Engine=Require-Dependency $Dependency }
    if ($Mode -eq 'Check') { Write-Host '[OK] Requirements available.'; exit 0 }
    $script:ReportNativeProgress=$true
    $script:InputDir=Join-Path $Folder 'Input'; $script:OutputDir=Join-Path $Folder 'Output'
    Ensure-Directory $script:InputDir; Ensure-Directory $script:OutputDir
    Write-Host "`n============================================================"
    Write-Host ('                    ' + $Name.ToUpperInvariant())
    Write-Host '============================================================'
    Write-Host $Description
    Write-Host ('Input : ' + $script:InputDir); Write-Host ('Output: ' + $script:OutputDir)
}
function Read-LocalChoice([string]$Mode,[string[]]$Labels,[int]$Default=1) {
    if ($Mode -eq 'Defaults') { return $Default }
    for ($i=0;$i -lt $Labels.Count;$i++) { Write-Host ('[{0}] {1}' -f ($i+1),$Labels[$i]) }
    Write-Host '[Q] Quit'
    while ($true) {
        $answer=Read-Host 'Select an option'
        if ($answer -match '^[Qq]$') { exit 0 }
        if ($answer -match '^\d{1,2}$' -and [int]$answer -ge 1 -and [int]$answer -le $Labels.Count) { return [int]$answer }
        Write-Host '[ERROR] Invalid selection.'
        if ([Console]::IsInputRedirected -and -not $answer) { throw 'No selection received.' }
    }
}
function Read-LocalNumber([string]$Prompt,[double]$Min,[double]$Max) {
    $text=Read-Host $Prompt
    if ($text -notmatch '^\d{1,7}(\.\d{1,3})?$') { throw 'Enter a number using a decimal point.' }
    $value=[double]::Parse($text,[Globalization.CultureInfo]::InvariantCulture)
    if ($value -lt $Min -or $value -gt $Max) { throw 'Number outside the documented range.' }
    $text
}
function Invoke-LocalBatch([IO.FileInfo[]]$Files,[scriptblock]$Name,[scriptblock]$Action,[switch]$DirectoryResult,[switch]$Aggregate) {
    if (-not $Files.Count) { Write-Host '[INFO] No supported input files. Add files to Input.'; exit 0 }
    $jobs=@(if($Aggregate){,$Files}else{$Files})
    $success=0; $failed=0; $skipped=0
    foreach ($job in $jobs) {
        $work=$null
        try {
            $file=if($Aggregate){$Files[0]}else{$job}
            $outName=& $Name $file
            if (-not $outName -or $outName -ne [IO.Path]::GetFileName($outName) -or $outName -match '[:*?"<>|]') { throw 'Invalid output name.' }
            $destination=Join-Path $script:OutputDir $outName
            if (Test-Path -LiteralPath $destination) { Write-Host ('[SKIPPED] '+$outName); $skipped++; continue }
            foreach($sourceFile in $(if($Aggregate){$Files}else{@($file)})) { if($sourceFile.FullName.Length -gt 240){throw 'Input path exceeds 240 characters.'} }
            if ($destination.Length -gt 200 -and $DirectoryResult) { throw 'Choose a shorter project path for directory output (maximum base 200 characters).' }
            if ($destination.Length -gt 240) { throw 'Output path exceeds 240 characters.' }
            Write-Host ('Processing: '+$(if($Aggregate){$Files.Count.ToString()+' files'}else{$file.Name}))
            $bytes=if($Aggregate){($Files|Measure-Object Length -Sum).Sum}else{$file.Length}
            Test-FreeSpace $script:OutputDir ([Math]::Max(16MB,[long]$bytes*3))
            $work=New-WorkDirectory $script:OutputDir
            $script:NativeWorkingDirectory=$work
            $source=Join-Path $work ('source'+$file.Extension)
            if(-not $Aggregate){Copy-Item -LiteralPath $file.FullName -Destination $source}
            $result=Join-Path $work ('result'+[IO.Path]::GetExtension($outName))
            if($DirectoryResult){$result=Join-Path $work 'result'; Ensure-Directory $result}
            & $Action $source $result $file $Files
            if ($DirectoryResult) {
                if(-not @(Get-SafeFiles $result $null -Recurse).Count){throw 'No output files were created.'}
                foreach($entry in (Get-SafeFiles $result $null -Recurse)){if((Join-Path $destination (Get-RelativeName $result $entry.FullName)).Length -gt 240){throw 'A result path exceeds 240 characters.'}}
                [IO.Directory]::Move($result,$destination)
            } else { Publish-File $result $destination }
            Write-Host ('[SUCCESS] '+$outName); $success++
        } catch { Write-Host ('[FAILED] '+$_.Exception.Message); $failed++ }
        finally { if($work){Remove-WorkDirectory $work $script:OutputDir} }
    }
    Write-Host ('Total: {0}  Successful: {1}  Failed: {2}  Skipped: {3}' -f $jobs.Count,$success,$failed,$skipped)
    if($failed){exit 1}; exit 0
}
function Invoke-LocalFF([string[]]$Arguments) {
    [void](Invoke-Checked $script:Engine (@('-hide_banner','-loglevel','error','-nostdin','-n')+$Arguments))
}
