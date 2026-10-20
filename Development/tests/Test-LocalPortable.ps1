# Copies already installed distributions into an isolated temporary project.
# No downloads, installers, registry changes or persistent dependency copies.
param([string]$FixtureDirectory)
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
$sourceRoot=$script:ProjectRoot
if(-not $FixtureDirectory){$previous=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'results.json') -Raw -Encoding UTF8 | ConvertFrom-Json; $FixtureDirectory=Join-Path ($previous.Sandbox.Replace('<PROJECT_ROOT>',$sourceRoot)) 'fixtures'}
$parent=Join-Path $PSScriptRoot '_sandbox'
Ensure-Directory $parent
$localRoot=New-WorkDirectory $parent
$results=New-Object 'Collections.Generic.List[object]'
$originalPath=$env:PATH
try {
    Test-FreeSpace $localRoot 1GB
    Ensure-Directory (Join-Path $localRoot 'System')
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'System\Shared') -Destination (Join-Path $localRoot 'System\Shared') -Recurse
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'START_HERE.bat') -Destination (Join-Path $localRoot 'START_HERE.bat')
    Ensure-Directory (Join-Path $localRoot 'System\Bin')
    foreach($name in @('ffmpeg','magick','ghostscript')) {
        $dependency=Get-Dependency $name
        if(-not $dependency){throw "Missing installed test dependency: $name"}
        $distribution=Split-Path $dependency.Path
        if((Split-Path $distribution -Leaf) -eq 'bin'){$distribution=Split-Path $distribution}
        $folder=if($name -eq 'magick'){'imagemagick'}else{$name}
        Copy-Item -LiteralPath $distribution -Destination (Join-Path $localRoot ('System\Bin\'+$folder)) -Recurse
    }
    $fixtures=$FixtureDirectory
    $env:PATH=$env:SystemRoot+'\System32;'+$env:SystemRoot
    # Reuse the actual BAT process harness without rerunning the main suite.
    $scriptText=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Run-Tests.ps1') -Raw
    $start=$scriptText.IndexOf('function Run-Bat('); $end=$scriptText.IndexOf('function Snapshot(')
    . ([scriptblock]::Create($scriptText.Substring($start,$end-$start)))
    foreach($item in @(
        @{Path='Tools\IMG\Image Resize\Image Resize.bat';Source='image.png'},
        @{Path='Tools\IMG\Image Watermark\Image Watermark.bat';Source='image.png'},
        @{Path='Tools\VID\Video Speed\Video Speed.bat';Source='video.mp4'},
        @{Path='Tools\PDF\Compress PDF\Compress PDF.bat';Source='document.pdf'},
        @{Path='Tools\UTI\Media Info\Media Info.bat';Source='video.mp4'}
    )) {
        $bat=Join-Path $localRoot $item.Path; $dir=Split-Path $bat
        Ensure-Directory $dir; Ensure-Directory (Join-Path $dir 'Input'); Ensure-Directory (Join-Path $dir 'Output')
        Copy-Item -LiteralPath (Join-Path $sourceRoot $item.Path) -Destination $bat
        Copy-Item -LiteralPath (Join-Path $FixtureDirectory $item.Source) -Destination (Join-Path $dir ('Input\'+$item.Source))
        $check=Run-Bat $bat '--check' '' $true
        $run=Run-Bat $bat '--defaults' '' $true
        $success=$check.Code -eq 0 -and $run.Code -eq 0 -and @(Get-SafeFiles (Join-Path $dir 'Output') $null -Recurse).Count -gt 0
        $results.Add([pscustomobject]@{Test=$item.Path;Passed=$success;Detail=($check.Text+$run.Text)})
        Write-Host ($(if($success){'PASS '}else{'FAIL '})+$item.Path+' using project local distributions with system discovery disabled.')
    }
    $setup=Run-Bat (Join-Path $localRoot 'START_HERE.bat') '--check' '' $true
    $success=$setup.Code -eq 0 -and ([regex]::Matches($setup.Text,'project local')).Count -eq 4
    $results.Add([pscustomobject]@{Test='START_HERE local priority';Passed=$success;Detail=$setup.Text})
    Write-Host ($(if($success){'PASS '}else{'FAIL '})+'START_HERE local priority')
} catch { $results.Add([pscustomobject]@{Test='Local portability infrastructure';Passed=$false;Detail=$_.Exception.Message}); Write-Host $_.Exception.Message }
finally {
    $env:PATH=$originalPath
    [pscustomobject]@{DateUTC=[DateTime]::UtcNow.ToString('o');Results=@($results.ToArray());BinaryCopiesRemoved=$true} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'local-portable-results.json') -Encoding UTF8
    Remove-WorkDirectory $localRoot $parent
}
if(@($results | Where-Object {-not $_.Passed}).Count){exit 1};exit 0
