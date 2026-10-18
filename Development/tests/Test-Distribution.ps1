$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\Download.ps1')
$root=$script:ProjectRoot
$results=New-Object 'Collections.Generic.List[object]'
$work=Join-Path $PSScriptRoot ('_work\dist-'+[guid]::NewGuid().ToString('N').Substring(0,8));Ensure-Directory $work
$ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$script:NativeWorkingDirectory=$work
function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Record([string]$Name,[string]$Detail){$results.Add([pscustomobject]@{Test=$Name;Passed=$true;Detail=$Detail});Write-Host ('PASS '+$Name)}
try {
    $arabic=-join([char[]]@(0x0646,0x0642,0x0644))
    $destination=Join-Path $work ('clean '+$arabic+' & ! %X% [1]')
    $build=Invoke-Native $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'System\Shared\Build.ps1'),'-Mode','Defaults','-Destination',$destination) 60000
    Assert ($build.Code -eq 0) ($build.Out+$build.Err)
    $manifest=Get-Content -LiteralPath (Join-Path $destination 'distribution-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($row in $manifest){Assert ((Get-FileHash -LiteralPath (Join-Path $destination $row.Path)).Hash -eq $row.SHA256) ('Manifest mismatch: '+$row.Path)}
    foreach($name in @('Development','tests','.git','System\Downloads')){Assert (-not (Test-Path -LiteralPath (Join-Path $destination $name))) ('Leaked '+$name)}
    $catalog=Get-Content -LiteralPath (Join-Path $destination 'System\Shared\tools.json') -Raw -Encoding UTF8|ConvertFrom-Json
    Assert ($catalog.Count -eq 55) 'Not all tools exported.'
    foreach($tool in $catalog){$bat=Join-Path $destination $tool.Path;Assert (Test-Path -LiteralPath $bat) 'Missing BAT.';Assert (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($bat,'.md'))) 'Missing MD.';foreach($name in @('Input','Output')){Assert ([IO.Directory]::Exists((Join-Path (Split-Path $bat) $name))) 'Missing empty folder.'}}
    Record 'Clean folder and manifest' '55 BATs and individual manuals; SHA-256 matched; no tests, backups, downloads or user files.'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($destination+'.zip')
    try{Assert ($null -ne $zip.GetEntry('Tools/UTI/Folder Compare/Input/Left/')) 'ZIP lost empty folders.';foreach($row in $manifest){Assert ($null -ne $zip.GetEntry($row.Path.Replace('\','/'))) 'ZIP lost a file.'}}finally{$zip.Dispose()}
    Record 'Clean ZIP' 'Every manifest file and empty Input/Output/Left/Right folder present.'
    $repeat=Invoke-Native $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'System\Shared\Build.ps1'),'-Mode','Defaults','-Destination',$destination) 30000
    Assert ($repeat.Code -ne 0) 'Existing distribution was overwritten.'
    foreach($row in $manifest){Assert ((Get-FileHash -LiteralPath (Join-Path $destination $row.Path)).Hash -eq $row.SHA256) 'Existing distribution changed.'}
    Record 'Build repeat safety' 'An existing destination was rejected; all original output hashes preserved.'
    $ghostscript=Get-Dependency 'ghostscript'
    Assert ($null -ne $ghostscript) 'Installed Ghostscript missing.'
    $portable=Join-Path $work 'installed-copy';Ensure-Directory $portable
    Copy-InstalledDependency $ghostscript $portable
    $script:ProjectRoot=$portable
    try{$local=Get-Dependency 'ghostscript' -LocalOnly}finally{$script:ProjectRoot=$root}
    Assert ($null -ne $local -and $local.Local) 'Copied Ghostscript was not discovered locally.'
    $render=Invoke-Native $local.Path @('-q','-dSAFER','-dBATCH','-dNOPAUSE','-sDEVICE=pdfwrite','-sOutputFile=copied.pdf','-c','/Helvetica findfont 12 scalefont setfont 72 720 moveto (Portable test) show showpage') 30000
    Assert ($render.Code -eq 0 -and (Get-Item -LiteralPath (Join-Path $work 'copied.pdf')).Length -gt 0) 'Copied Ghostscript could not render.'
    Record 'Installed Ghostscript portable preparation' 'Copied full installed tree into isolated test folder; hash checks, local discovery and real PDF rendering succeeded; no installer/download.'
    # All moves remain within the freshly created test workspace.
    $from=[IO.Path]::GetFullPath((Join-Path $portable 'System\Bin\ghostscript'));$to=[IO.Path]::GetFullPath((Join-Path $destination 'System\Bin\ghostscript'))
    Assert ($from.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase) -and $to.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase)) 'Unsafe test move.'
    [IO.Directory]::Move($from,$to)
    Assert (Test-Path -LiteralPath (Join-Path $destination 'System\Shared\Build.ps1')) 'Release cannot build a clean copy.'
    Ensure-Directory (Join-Path $destination 'tests');[IO.File]::WriteAllText((Join-Path $destination 'tests\private-test.log'),'must stay out')
    [IO.File]::WriteAllText((Join-Path $destination 'Tools\UTI\File Inventory\Input\private.txt'),'must stay out')
    $second=Join-Path $work 'with-local-bin'
    $build=Invoke-Native $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $destination 'System\Shared\Build.ps1'),'-Mode','Defaults','-Destination',$second,'-IncludeLocalDependencies') 60000
    Assert ($build.Code -eq 0) ($build.Out+$build.Err)
    Assert (-not (Test-Path -LiteralPath (Join-Path $second 'tests')) -and -not (Test-Path -LiteralPath (Join-Path $second 'Tools\UTI\File Inventory\Input\private.txt'))) 'Rebuild copied private test data.'
    $a=@(Get-SafeFiles (Join-Path $destination 'System\Bin') $null -Recurse);$b=@(Get-SafeFiles (Join-Path $second 'System\Bin') $null -Recurse)
    Assert ($a.Count -eq $b.Count -and $a.Count -gt 0) 'Local program tree was incomplete.'
    foreach($file in $a){$relative=Get-RelativeName (Join-Path $destination 'System\Bin') $file.FullName;$sourceHash=(Get-FileHash -LiteralPath $file.FullName).Hash;$targetHash=(Get-FileHash -LiteralPath (Join-Path $second ('System\Bin\'+$relative))).Hash;Assert ($sourceHash -eq $targetHash) 'Local tree byte mismatch.'}
    Record 'Distribution with local dependencies' 'Complete copied Ghostscript tree/resources preserved; rebuilding excluded private Input and test files.'
} catch {$results.Add([pscustomobject]@{Test='Distribution';Passed=$false;Detail=$_.Exception.Message.Replace($root,'<PROJECT_ROOT>')});Write-Host ('FAIL '+$_.Exception.Message)}
$results|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'distribution-results.json') -Encoding UTF8
if(@($results|Where-Object {-not $_.Passed}).Count){exit 1};exit 0
