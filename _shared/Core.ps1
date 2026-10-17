# Shared Windows PowerShell 5.1 runtime. No global environment changes.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
    [Console]::InputEncoding = New-Object Text.UTF8Encoding($false)
} catch { } # Some hosts do not expose console handles; filesystem APIs stay Unicode.
$script:ProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function ConvertTo-NativeArgument([string]$Value) {
    # CommandLineToArgvW / Microsoft CRT quoting; never invoke cmd.exe.
    '"' + [regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}
function Invoke-Native([string]$Executable, [string[]]$Arguments, [int]$Timeout = 0) {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $info.UseShellExecute = $false
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
        $process.StandardInput.Close()
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
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
function Get-Dependency([ValidateSet('ffmpeg','ffprobe','magick','ghostscript')][string]$Name, [switch]$LocalOnly) {
    $candidates = New-Object 'Collections.Generic.List[string]'
    $names = @($Name + '.exe')
    if ($Name -eq 'ghostscript') { $names = @('gswin64c.exe','gswin32c.exe') }
    $folder = if ($Name -eq 'ffprobe') { 'ffmpeg' } elseif ($Name -eq 'magick') { 'imagemagick' } else { $Name }
    $local = Join-Path $script:ProjectRoot ('_bin\' + $folder)
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
            }
        }
    }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try {
            $versionArgs = if ($Name -eq 'ghostscript') { @('--version') } else { @('-version') }
            $version = Invoke-Native $candidate $versionArgs 15000
            $text = $version.Out + $version.Err
            $valid = $version.Code -eq 0
            switch ($Name) {
                'magick' { $valid = $valid -and $text -match 'ImageMagick 7\.' }
                'ffmpeg' { $valid = $valid -and $text -match 'ffmpeg version (?:n)?(\d+)' -and [int]$Matches[1] -ge 6 }
                'ffprobe' { $valid = $valid -and $text -match 'ffprobe version (?:n)?(\d+)' -and [int]$Matches[1] -ge 6 }
                'ghostscript' { $valid = $valid -and $text.Trim() -match '^\d+\.\d+' -and [version]$text.Trim() -ge [version]'10.05.0' }
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
