param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
try {
    $destinationPath=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
    if(Test-Path -LiteralPath $destinationPath){throw 'Choose a NEW destination folder. Existing files are never overwritten.'}
    $manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $directories=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'directories.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $PSScriptRoot 'original.zip'))
    try {
        [void][IO.Directory]::CreateDirectory($destinationPath)
        foreach($relative in $directories){
            $path=[IO.Path]::GetFullPath((Join-Path $destinationPath $relative))
            if(-not $path.StartsWith($destinationPath+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe saved directory path.'}
            [void][IO.Directory]::CreateDirectory($path)
        }
        foreach($file in $manifest){
            $path=[IO.Path]::GetFullPath((Join-Path $destinationPath $file.Path))
            if(-not $path.StartsWith($destinationPath+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe saved file path.'}
            $entry=$archive.GetEntry($file.Path.Replace('\','/'))
            if(-not $entry){throw "Missing backup entry: $($file.Path)"}
            $inputStream=$entry.Open(); $outputStream=[IO.File]::Open($path,[IO.FileMode]::CreateNew)
            try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
            if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.SHA256){throw "Backup checksum mismatch: $($file.Path)"}
            [IO.File]::SetLastWriteTimeUtc($path,$entry.LastWriteTime.UtcDateTime)
        }
    } finally {$archive.Dispose()}
    Write-Host "[SUCCESS] Original files and empty folders restored to: $destinationPath"
    exit 0
}catch{Write-Host ('[ERROR] '+$_.Exception.Message);exit 1}
