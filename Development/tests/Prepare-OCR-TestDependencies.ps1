param([switch]$Approved)
if(-not $Approved){throw 'Explicit user consent is required before downloading.'}
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot)
$folder=Join-Path $PSScriptRoot '_work\dependencies-20261021'
[void][IO.Directory]::CreateDirectory($folder)
$assets=@(
 @{Name='qpdf.zip';Url='https://github.com/qpdf/qpdf/releases/download/v12.4.2/qpdf-12.4.2-msvc64.zip';SHA256='db87077e683630c1217e0e8f9a20a9749d952ab676e881c3689187763a5de25d'},
 @{Name='tesseract.exe';Url='https://github.com/tesseract-ocr/tesseract/releases/download/5.5.3/tesseract-ocr-w64-setup-5.5.3.20260724.exe';SHA256='bee9e3434bd94fd65387d9be28cd467a41f61b1275383b55b0f59a1331270ae4'},
 @{Name='7zip.exe';Url='https://github.com/ip7z/7zip/releases/download/26.04/7z2604-x64.exe';SHA256='d54bf805f9f3704d1e8db2fa3498ae7ef2df0312b40b558e7c71c734430a665d'},
 @{Name='7zr.exe';Url='https://github.com/ip7z/7zip/releases/download/26.04/7zr.exe';SHA256='256feca8e274e5da655e2a284fabafd9f554365eb164862089dacd4e8276d282'}
)
$records=@()
foreach($asset in $assets){
 $path=Join-Path $folder $asset.Name
 if(-not (Test-Path -LiteralPath $path)){Invoke-WebRequest -Uri $asset.Url -OutFile $path -TimeoutSec 180}
 if((Get-FileHash -LiteralPath $path).Hash -ne $asset.SHA256){throw ('Hash mismatch: '+$asset.Name)}
 $records+=[pscustomobject]@{File=$asset.Name;Url=$asset.Url;SHA256=$asset.SHA256;Bytes=(Get-Item -LiteralPath $path).Length;Verified='Official GitHub release asset SHA-256 digest'}
 Write-Host ('Verified '+$asset.Name)
}
$models=@{ara='c8d129c67821c1592cac46836686b057ecc203dc';eng='bbef4675053b5b468cdb477053e28b1c698ba08e';osd='527457ca8f8fe1fda7c2f88bce3c0e4be12be9d0'}
foreach($language in @('ara','eng','osd')){
 $name=$language+'.traineddata';$path=Join-Path $folder $name
 $url='https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/65727574dfcd264acbb0c3e07860e4e9e9b22185/'+$name
 if(-not (Test-Path -LiteralPath $path)){Invoke-WebRequest -Uri $url -OutFile $path -TimeoutSec 180}
 $bytes=[IO.File]::ReadAllBytes($path);$header=[Text.Encoding]::ASCII.GetBytes(('blob '+$bytes.Length+[char]0));$sha=[Security.Cryptography.SHA1]::Create()
 try{$gitHash=[BitConverter]::ToString($sha.ComputeHash(([byte[]]($header+$bytes)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 if($gitHash -ne $models[$language]){throw ('Official pinned Git blob mismatch: '+$name)}
 $records+=[pscustomobject]@{File=$name;Url=$url;SHA256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant();Bytes=$bytes.Length;Verified=('Pinned official Git blob '+$gitHash+'; SHA-256 computed after verification for reproducible setup')}
 Write-Host ('Verified '+$name)
}
$records|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $root 'Development\Reports\ocr-download-provenance.json') -Encoding UTF8
# Extract only: the installer files are NEVER executed.
$seven=Join-Path $folder 'sevenzip'
if(-not (Test-Path -LiteralPath (Join-Path $seven '7z.exe'))){& (Join-Path $folder '7zr.exe') x (Join-Path $folder '7zip.exe') ('-o'+$seven) -y;if($LASTEXITCODE){throw '7-Zip extraction failed.'}}
$tess=Join-Path $folder 'tesseract'
if(-not (Test-Path -LiteralPath $tess)){& (Join-Path $seven '7z.exe') x (Join-Path $folder 'tesseract.exe') ('-o'+$tess) -y;if($LASTEXITCODE){throw 'Tesseract extraction failed.'}}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$qpdf=Join-Path $folder 'qpdf'
if(-not (Test-Path -LiteralPath $qpdf)){[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $folder 'qpdf.zip'),$qpdf)}
Write-Host ('Extracted, without installation: '+$folder)
