param([switch]$CheckOnly)
. (Join-Path $PSScriptRoot 'Core.ps1')
. (Join-Path $PSScriptRoot 'Archives.ps1')
. (Join-Path $PSScriptRoot 'Download.ps1')
function Show-Dependencies {
    $missing=New-Object 'Collections.Generic.List[string]'
    foreach ($name in @('ffmpeg','ffprobe','magick','ghostscript')) {
        $dependency=Get-Dependency $name
        if ($dependency) { Write-Host ('[OK] {0} | {1} | {2}' -f $name,$(if($dependency.Local){'project local'}else{'system'}),$dependency.Path); Write-Host ('     ' + $dependency.Version) }
        else { Write-Host ('[MISSING] ' + $name); $missing.Add($name) }
        $users=@($script:ToolCatalog | Where-Object Dependency -eq $name | ForEach-Object Name)
        if($users.Count){Write-Host ('     Used by: ' + ($users -join ', '))}
    }
    return ,$missing
}
try {
    if ([Environment]::OSVersion.Version.Major -lt 10 -or $PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Windows 10/11 and Windows PowerShell 5.1 are required.' }
    $architecture=if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    Write-Host "`n============================================================"
    Write-Host '                     tOOls Bat - START HERE'
    Write-Host "============================================================"
    Write-Host ('Project: ' + $script:ProjectRoot)
    Write-Host ('Windows: ' + [Environment]::OSVersion.Version + ' | Architecture: ' + $architecture)
    Write-Host ('PowerShell: ' + $PSVersionTable.PSVersion)
    Write-Host 'Administrator is not required. No PATH, Registry or Windows settings are changed.'
    $packages=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'packages.json') -Raw | ConvertFrom-Json
    $script:ToolCatalog=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    do {
        $missing=Show-Dependencies
        if ($CheckOnly) { if ($missing.Count) { exit 3 }; exit 0 }
        if (-not $missing.Count) { Write-Host '[SUCCESS] All project requirements are available.' }
        else {
            Write-Host 'Only choose packages for the tools you intend to use. Offline/manual setup is supported.'
            foreach ($package in $packages) {
                if ($package.Id -notin $missing -and -not ($package.Id -eq 'ffmpeg' -and 'ffprobe' -in $missing)) { continue }
                if ($architecture -ne $package.Arch) { Write-Host ('[MANUAL] No automatic package for ' + $package.Name + ' on ' + $architecture + '. See docs\DEPENDENCIES.md.'); continue }
                Write-Host ("`n{0}, fixed version {1}, approximately {2} MB" -f $package.Name,$package.Version,$package.ApproxMB)
                Write-Host ('Source : ' + $package.Source)
                Write-Host ('File   : ' + $package.Url)
                Write-Host ('License: ' + $package.License)
                $answer=Read-Host 'Download this package? [Y/N; default N]'
                if ($answer -cne 'Y' -and $answer -cne 'y') { continue }
                try { Install-PortablePackage $package $script:ProjectRoot }
                catch { Write-Host ('[FAILED] ' + $_.Exception.Message); Write-Host 'Previous setup was preserved. Check disk space, permissions and internet access, then retry.' }
            }
        }
        Write-Host "`nAfter setup: open the relevant BAT, place files in its Input folder, select options. Results are in Output."
        Write-Host 'README.md lists all tools and defaults. Every BAT supports --help and --check.'
        $missing=Show-Dependencies
        $again=Read-Host 'Recheck / retry missing packages? [Y/N; default N]'
    } while ($again -match '^[Yy]$')
    if ($missing.Count) { Write-Host '[INFO] Setup is partial. Tools whose requirements are present can be used.'; exit 3 }
    exit 0
} catch { Write-Host ('[ERROR] ' + $_.Exception.Message); exit 2 }
