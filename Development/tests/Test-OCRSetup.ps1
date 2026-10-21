$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\..\System\Shared\Core.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\Archives.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\OCR.ps1')
. (Join-Path $PSScriptRoot '..\..\System\Shared\Download.ps1')
$root=$script:ProjectRoot
# A short, private project root avoids exceeding the documented 240-character
# limit while unpacking upstream SDK/documentation paths. Keep normal test logs
# in Development; no user directory or existing distribution is touched.
$work=Join-Path $root ('.setup-'+[guid]::NewGuid().ToString('N').Substring(0,8));Ensure-Directory $work
$target=Join-Path $work 'ع &!%[1]';Ensure-Directory (Join-Path $target 'System')
Copy-Item -LiteralPath (Join-Path $root 'System\Shared') -Destination (Join-Path $target 'System\Shared') -Recurse
Copy-Item -LiteralPath (Join-Path $root 'START_HERE.bat') -Destination (Join-Path $target 'START_HERE.bat')
$assets=Join-Path $PSScriptRoot '_work\dependencies-20261021';$records=Get-Content -LiteralPath (Join-Path $root 'Development\Reports\ocr-download-provenance.json') -Raw -Encoding UTF8|ConvertFrom-Json
$packages=Get-Content -LiteralPath (Join-Path $root 'System\Shared\packages.json') -Raw|ConvertFrom-Json
$results=New-Object 'Collections.Generic.List[object]'
function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Case([string]$Name,[scriptblock]$Action){try{& $Action;$results.Add([pscustomobject]@{Test=$Name;Passed=$true});Write-Host ('PASS '+$Name)}catch{$results.Add([pscustomobject]@{Test=$Name;Passed=$false;Detail=$_.Exception.Message.Replace($root,'<PROJECT_ROOT>')});Write-Host ('FAIL '+$Name+': '+$_.Exception.Message)}}
$fetch={param($url,$path)$record=$records|Where-Object Url -ceq $url;if(-not $record){throw 'No network allowed: URL was not in the already approved download set.'};[IO.File]::Copy((Join-Path $assets $record.File),$path,$false)}
Case 'Complete Tesseract extracted by actual setup code; no installer executed' {
 Install-PortablePackage ($packages|Where-Object Id -eq tesseract) $target $fetch
 Assert (Test-Path -LiteralPath (Join-Path $target 'System\Bin\Tesseract\tesseract.exe')) 'Executable missing.'
 Assert (Test-Path -LiteralPath (Join-Path $target 'System\Bin\Tesseract\tessdata\pdf.ttf')) 'PDF font missing.'
 Assert (@(Get-SafeFiles (Join-Path $target 'System\Bin\Tesseract') @('.dll')).Count -gt 20) 'Runtime DLLs missing.'
 Assert (-not (Test-Path -LiteralPath (Join-Path $target 'System\Bin\Tesseract\$PLUGINSDIR'))) 'Installer plugins copied into runtime.'
}
Case 'Three language packages verified and initialized using Unicode-safe paths' {
 foreach($id in @('tessdata-ara','tessdata-eng','tessdata-osd')){Install-PortablePackage ($packages|Where-Object Id -eq $id) $target $fetch}
 $script:ProjectRoot=$target
 try{$configuration=Get-OCRConfiguration;Test-OCRLanguages $configuration 'ara+eng';Assert ($configuration.Languages.Count -eq 3) 'Language inventory differs.'}finally{$script:ProjectRoot=$root}
}
Case 'qpdf portable ZIP prepared by actual setup code' {Install-PortablePackage ($packages|Where-Object Id -eq qpdf) $target $fetch;$script:ProjectRoot=$target;try{Assert ([bool](Get-Dependency qpdf -LocalOnly)) 'Local qpdf not usable.'}finally{$script:ProjectRoot=$root}}
Case 'Language cache reuse and prior runtime preservation' {
 $dir=Join-Path $target 'System\Bin';$before=@(Get-SafeFiles $dir $null -Recurse|ForEach-Object{(Get-RelativeName $dir $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n"
 foreach($id in @('tessdata-ara','tessdata-eng','tessdata-osd')){Install-PortablePackage ($packages|Where-Object Id -eq $id) $target {throw 'Unexpected fetch: cached models should be reused.'}}
 $after=@(Get-SafeFiles $dir $null -Recurse|ForEach-Object{(Get-RelativeName $dir $_.FullName)+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}) -join "`n";Assert ($before -ceq $after) 'Idempotent language preparation changed files.'
}
Case 'Optional model pathway validates pinned Git blob using approved Arabic data' {
 $data=Join-Path $target 'System\Bin\Tesseract\tessdata';$path=Join-Path $data 'ara.traineddata';[IO.File]::Move($path,($path+'.saved'))
 try{Install-OptionalOCRLanguage ([pscustomobject]@{Code='ara';Bytes=1432056;GitBlobSHA1='c8d129c67821c1592cac46836686b057ecc203dc';Url=($records|Where-Object File -eq ara.traineddata).Url}) $target $fetch;Assert ((Get-FileHash -LiteralPath $path).Hash -eq (Get-FileHash -LiteralPath ($path+'.saved')).Hash) 'Optional model bytes changed.'}
 finally{if(Test-Path -LiteralPath ($path+'.saved')){[IO.File]::Delete(($path+'.saved'))}}
}
Case 'Partial/corrupt package refused without publishing a runtime' {
 $other=Join-Path $work 'failed';$failed=$false
 try{Install-PortablePackage ($packages|Where-Object Id -eq tesseract) $other {param($url,$path)[IO.File]::WriteAllText($path,'partial download')}}catch{$failed=$true}
 Assert ($failed -and -not (Test-Path -LiteralPath (Join-Path $other 'System\Bin\Tesseract'))) 'Invalid runtime published.'
}
Case 'Offline download failure is explicit and preserves files' {
 $other=Join-Path $work 'offline';$failed=$false
 try{Install-PortablePackage ($packages|Where-Object Id -eq tesseract) $other {throw 'Offline fixture; no network requested.'}}catch{$failed=$true}
 Assert ($failed -and -not (Test-Path -LiteralPath (Join-Path $other 'System\Bin\Tesseract'))) 'Offline setup claimed success.'
}
Case 'Real START_HERE check repeated after portable preparation' {
 $ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
 foreach($i in 1,2){$r=Invoke-Native $ps @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $target 'System\Shared\Setup.ps1'),'-CheckOnly') 60000;Assert ($r.Code -eq 0 -and $r.Out -match 'language ara initialized' -and $r.Out -match 'project local') ($r.Out+$r.Err)}
}
Case 'Missing models produce partial setup without a success claim' {
 $path=Join-Path $target 'System\Bin\Tesseract\tessdata\ara.traineddata';[IO.File]::Move($path,($path+'.saved'))
 try{$r=Invoke-Native (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $target 'System\Shared\Setup.ps1'),'-CheckOnly') 60000;Assert ($r.Code -eq 3 -and $r.Out -match '\[MISSING\].*ara' -and $r.Out -notmatch '\[SUCCESS\]') 'Missing language readiness is misleading.'}finally{[IO.File]::Move(($path+'.saved'),$path)}
}
$results.ToArray()|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'ocr-setup-results.json') -Encoding UTF8
$archiveRoot=Join-Path $PSScriptRoot '_work';Ensure-Directory $archiveRoot
$resolved=[IO.Path]::GetFullPath($work);$archive=[IO.Path]::GetFullPath((Join-Path $archiveRoot ([IO.Path]::GetFileName($work))))
if([IO.Path]::GetDirectoryName($resolved) -ne [IO.Path]::GetFullPath($root) -or [IO.Path]::GetFileName($resolved) -notmatch '^\.setup-[a-f0-9]{8}$' -or -not $archive.StartsWith([IO.Path]::GetFullPath($archiveRoot)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe private test archive path.'}
if(Test-Path -LiteralPath $archive){throw 'Private test archive already exists; existing files preserved.'}
[IO.Directory]::Move($resolved,$archive) # Preserve all test runtime files; no deletion.
if(@($results|Where-Object{-not $_.Passed}).Count){exit 1};exit 0
