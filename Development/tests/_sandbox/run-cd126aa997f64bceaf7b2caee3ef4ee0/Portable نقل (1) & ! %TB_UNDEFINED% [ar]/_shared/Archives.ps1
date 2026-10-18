function Zip-Create([IO.FileInfo[]]$Files,[string]$Root,[string]$Target) {
    Add-Type -AssemblyName System.IO.Compression
    $stream = [IO.File]::Open($Target,[IO.FileMode]::CreateNew)
    $zip = New-Object IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Create,$false)
    try {
        foreach($directory in (Get-SafeDirectories $Root)) {
            [void]$zip.CreateEntry((Get-RelativeName $Root $directory.FullName).Replace('\','/') + '/')
        }
        foreach ($file in $Files) {
            $entry = $zip.CreateEntry((Get-RelativeName $Root $file.FullName).Replace('\','/'),[IO.Compression.CompressionLevel]::Optimal)
            $source = [IO.File]::OpenRead($file.FullName)
            $destination = $entry.Open()
            try { $source.CopyTo($destination) } finally { $source.Dispose(); $destination.Dispose() }
        }
    } finally { $zip.Dispose(); $stream.Dispose() }
}
function Zip-Extract([string]$Archive,[string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $seen = @{}
        [long]$total = 0
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('/','\')
            if ($name -match '(^[\\/]|:|(^|\\)\.\.(\\|$)|[<>"|?*])' -or $name -match '(^|\\)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|\\|$)' -or $name -match '[. ](\\|$)') { throw "Unsafe ZIP entry: $name" }
            if (($entry.ExternalAttributes -shr 16 -band 0xF000) -eq 0xA000) { throw 'ZIP symlinks are not accepted.' }
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $name))
            if (-not $target.StartsWith($Destination.TrimEnd('\') + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'ZIP path escapes destination.' }
            if ($seen.ContainsKey($target)) { throw 'Duplicate ZIP entry.' }
            $seen[$target] = $true
            if ($target.Length -gt 240) { throw 'ZIP entry exceeds the supported path length (240).' }
            $total += $entry.Length
            if ($total -gt 20GB -or $zip.Entries.Count -gt 100000) { throw 'ZIP exceeds the safe extraction limits: 20 GB / 100000 entries.' }
        }
        Test-FreeSpace $Destination ($total + 16MB)
        Ensure-Directory $Destination
        foreach ($entry in $zip.Entries) {
            $target = Join-Path $Destination $entry.FullName.Replace('/','\')
            if ($entry.FullName.EndsWith('/')) { Ensure-Directory $target; continue }
            Ensure-Directory ([IO.Path]::GetDirectoryName($target))
            $source = $entry.Open()
            $destinationStream = [IO.File]::Open($target,[IO.FileMode]::CreateNew)
            try { $source.CopyTo($destinationStream) } finally { $source.Dispose(); $destinationStream.Dispose() }
            if ((Get-Item -LiteralPath $target).Length -ne $entry.Length) { throw 'Incomplete ZIP entry.' }
        }
    } finally { $zip.Dispose() }
}
