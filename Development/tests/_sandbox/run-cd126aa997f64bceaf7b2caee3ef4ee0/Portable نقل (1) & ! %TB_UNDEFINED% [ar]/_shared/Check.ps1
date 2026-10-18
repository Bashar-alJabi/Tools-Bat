param([Parameter(Mandatory=$true)][string]$Name)
. (Join-Path $PSScriptRoot 'Core.ps1')
try {
    $dependency = Get-Dependency $Name
    if (-not $dependency) { throw "Missing or incompatible $Name. Run START_HERE.bat." }
    Write-Host ('[OK] ' + $dependency.Version)
    Write-Host ('     ' + $dependency.Path)
    exit 0
} catch { Write-Host ('[ERROR] ' + $_.Exception.Message); exit 3 }
