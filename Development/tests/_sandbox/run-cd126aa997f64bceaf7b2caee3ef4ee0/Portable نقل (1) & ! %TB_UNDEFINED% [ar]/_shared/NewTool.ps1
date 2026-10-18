param([string]$Tool,[string]$ToolDir,[ValidateSet('Interactive','Defaults','Check','Help','Verify')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot 'Core.ps1')
try {
    $dependencies = @{ 'Audio Converter'='ffmpeg'; 'Video Thumbnail'='ffmpeg'; 'Media Info'='ffprobe'; 'Merge PDF'='ghostscript' }
    if ($Mode -eq 'Help') { Write-Host 'Put source files in Input. Results are saved in Output; existing results are skipped.'; Write-Host '--check checks dependencies; --defaults uses the documented default; File Hashes also accepts --verify.'; exit 0 }
    if ($dependencies.ContainsKey($Tool)) { $null=Require-Dependency $dependencies[$Tool] }
    if ($Mode -eq 'Check') { Write-Host '[OK] Requirements available.'; exit 0 }
    if ($Mode -eq 'Interactive') {
        Write-Host "`n============================================================"
        Write-Host ('                    ' + $Tool.ToUpperInvariant())
        Write-Host "============================================================"
        Write-Host ('Input : ' + (Join-Path $ToolDir 'Input'))
        Write-Host ('Output: ' + (Join-Path $ToolDir 'Output'))
        if ($Tool -eq 'Audio Converter') {
            Write-Host '[1] MP3  [2] WAV  [3] FLAC  [4] M4A  [5] Opus  [Q] Quit'
            $selection=Read-Host 'Select output format'
            if ($selection -match '^[Qq]$') { exit 0 }
            if ($selection -notmatch '^[1-5]$') { throw 'Invalid selection.' }
            $env:FORMAT=@('mp3','wav','flac','m4a','opus')[[int]$selection-1]
        } elseif ($Tool -eq 'File Hashes') {
            Write-Host '[1] Create SHA-256 manifest  [2] Verify Output\hashes.csv  [Q] Quit'
            $selection=Read-Host 'Select an option'
            if ($selection -match '^[Qq]$') { exit 0 }
            if ($selection -notmatch '^[12]$') { throw 'Invalid selection.' }
            if ($selection -eq '2') { $Mode='Verify' }
        } else {
            if ($Tool -eq 'Merge PDF') { Write-Host 'PDFs are merged in filename order. Prefix names with 001, 002, ... to control order.' }
            if ($Tool -eq 'ZIP Backup') { Write-Host 'Creates Output\backup.zip from the full Input tree, including hidden files. Links are skipped.' }
            if ($Tool -eq 'ZIP Extract') { Write-Host 'Each ZIP is extracted into its own NEW folder. Limits: 20 GB and 100000 entries.' }
            if ($Tool -eq 'Duplicate Finder') { Write-Host 'Creates a report only. No source files are removed.' }
            Write-Host '[1] Start  [Q] Quit'
            $selection=Read-Host 'Select an option'
            if ($selection -match '^[Qq]$') { exit 0 }
            if ($selection -ne '1') { throw 'Invalid selection.' }
        }
    }
    if ($Mode -eq 'Verify') {
        if ($Tool -ne 'File Hashes') { throw '--verify is supported by File Hashes only.' }
        $inputDir=[IO.Path]::GetFullPath((Join-Path $ToolDir 'Input')).TrimEnd('\')
        $manifest=Join-Path $ToolDir 'Output\hashes.csv'
        $rows=@(Import-Csv -LiteralPath $manifest -Encoding UTF8)
        $bad=0
        $seen=@{}
        foreach ($row in $rows) {
            if ($row.Path -match '(^[\\/]|:|(^|[\\/])\.\.([\\/]|$))' -or $row.SHA256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'Invalid manifest row.' }
            $path=[IO.Path]::GetFullPath((Join-Path $inputDir $row.Path))
            if (-not $path.StartsWith($inputDir+'\',[StringComparison]::OrdinalIgnoreCase) -or $seen.ContainsKey($path)) { throw 'Invalid/duplicate manifest path.' }
            $seen[$path]=$true
            $linked=$false; $ancestor=$path
            while ($ancestor.Length -gt $inputDir.Length) {
                if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { $linked=$true; break }
                $ancestor=[IO.Path]::GetDirectoryName($ancestor)
            }
            if ($linked -or -not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $row.SHA256) { Write-Host ('[FAILED] ' + $row.Path); $bad++ }
            else { Write-Host ('[OK] ' + $row.Path) }
        }
        foreach ($extra in (Get-SafeFiles $inputDir $null -Recurse)) { if (-not $seen.ContainsKey($extra.FullName)) { Write-Host ('[UNLISTED] ' + (Get-RelativeName $inputDir $extra.FullName)); $bad++ } }
        if ($bad) { exit 1 }; exit 0
    }
    & (Join-Path $PSScriptRoot 'ToolRunner.ps1') -Tool $Tool -ToolDir $ToolDir -Defaults:($Mode -eq 'Defaults')
    exit $LASTEXITCODE
} catch { Write-Host ('[ERROR] ' + $_.Exception.Message); exit 2 }
