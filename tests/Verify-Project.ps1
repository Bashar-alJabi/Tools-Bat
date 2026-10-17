$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$results=New-Object 'Collections.Generic.List[object]'
try {
    $parseErrors=@()
    foreach($file in (Get-ChildItem -LiteralPath (Join-Path $root '_shared'),(Join-Path $root '_original'),$PSScriptRoot -Filter '*.ps1' -File)) {
        $tokens=$null; $issues=$null
        [void][Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$issues)
        $parseErrors+=$issues
    }
    if($parseErrors.Count){throw ($parseErrors -join "`n")}
    $results.Add([pscustomobject]@{Test='PowerShell parse';Passed=$true;Detail='All production and test scripts parsed.'})
    $catalog=Get-Content -LiteralPath (Join-Path $root '_shared\tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($tool in $catalog){
        if(-not (Test-Path -LiteralPath (Join-Path $root $tool.Path))){throw "Missing tool: $($tool.Path)"}
        if($tool.Dependency -and $tool.Dependency -notin @('ffmpeg','ffprobe','magick','ghostscript')){throw 'Unregistered dependency.'}
    }
    $results.Add([pscustomobject]@{Test='Catalog completeness';Passed=$true;Detail="$($catalog.Count) tool launchers, dependencies registered."})
    $packages=Get-Content -LiteralPath (Join-Path $root '_shared\packages.json') -Raw | ConvertFrom-Json
    foreach($package in $packages){
        if($package.SHA256 -notmatch '^[a-f0-9]{64}$' -or $package.Url -notmatch '^https://' -or $package.Url -match '/latest/'){throw 'Unpinned package.'}
    }
    $results.Add([pscustomobject]@{Test='Pinned packages';Passed=$true;Detail='All three package URLs and SHA-256 values are fixed.'})
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $root '_original\original.zip'))
    $manifest=Get-Content -LiteralPath (Join-Path $root '_original\manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    try {
        foreach($original in $manifest) {
            $entry=$archive.GetEntry($original.Path.Replace('\','/'))
            if(-not $entry){throw "Original backup entry missing: $($original.Path)"}
            $stream=$entry.Open(); $sha=[Security.Cryptography.SHA256]::Create()
            try{$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
            if($hash -ne $original.SHA256){throw "Original backup checksum differs: $($original.Path)"}
        }
    } finally {$archive.Dispose()}
    . (Join-Path $root '_shared\Core.ps1')
    $work=New-WorkDirectory (Join-Path $PSScriptRoot '_sandbox')
    try {
        $restored=Join-Path $work 'restored'
        $restore=Invoke-Native (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root '_original\Restore-ToFolder.ps1'),'-Destination',$restored) 30000
        if($restore.Code -ne 0){throw ($restore.Out+$restore.Err)}
        $directories=Get-Content -LiteralPath (Join-Path $root '_original\directories.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach($relative in $directories){if(-not [IO.Directory]::Exists((Join-Path $restored $relative))){throw 'Empty original folder was not restored.'}}
        foreach($file in $manifest){if((Get-FileHash -LiteralPath (Join-Path $restored $file.Path)).Hash -ne $file.SHA256){throw 'Restored file differs.'}}
        $repeat=Invoke-Native (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root '_original\Restore-ToFolder.ps1'),'-Destination',$restored) 30000
        if($repeat.Code -eq 0){throw 'Restore accepted an existing destination.'}
    } finally {Remove-WorkDirectory $work (Join-Path $PSScriptRoot '_sandbox')}
    $results.Add([pscustomobject]@{Test='Original snapshot integrity';Passed=$true;Detail="$($manifest.Count) original file hashes and $($directories.Count) directories restored; existing destination rejected."})
    foreach($tool in $catalog){
        $dir=Split-Path (Join-Path $root $tool.Path)
        foreach($name in @('Input','Output')){if(@(Get-ChildItem -LiteralPath (Join-Path $dir $name) -File -Recurse -Force | Where-Object {$_.Name -ne '.gitkeep'}).Count){throw 'Test data leaked into a production Input/Output folder.'}}
    }
    if(@(Get-ChildItem -LiteralPath (Join-Path $root '_bin') -Recurse -File -Force | Where-Object {$_.Name -ne '.gitkeep'}).Count){throw 'A test program was left in the production _bin folder.'}
    $results.Add([pscustomobject]@{Test='Production input/output/bin isolation';Passed=$true;Detail='No test data, dependency installation, or program download in production folders.'})
    . (Join-Path $root '_shared\Core.ps1')
    $script:ReportNativeProgress=$true
    $native=Invoke-Native (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @('-NoProfile','-Command','Start-Sleep -Seconds 2; Write-Output done')
    if($native.Code -ne 0 -or $native.Out.Trim() -ne 'done'){throw 'Native progress/output regression.'}
    $results.Add([pscustomobject]@{Test='Native progress/output';Passed=$true;Detail='Progress reporting, process completion and asynchronous output capture verified.'})
} catch {$results.Add([pscustomobject]@{Test='Verification';Passed=$false;Detail=$_.Exception.Message})}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verification-results.json') -Encoding UTF8
$results | ForEach-Object{Write-Host ($(if($_.Passed){'PASS '}else{'FAIL '})+$_.Test+': '+$_.Detail)}
if(@($results|Where-Object{-not $_.Passed}).Count){exit 1};exit 0
