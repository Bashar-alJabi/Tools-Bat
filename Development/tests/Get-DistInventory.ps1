param([string]$Report)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$dist=Join-Path $root 'dist'
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Tree([string]$Directory){
    foreach($item in (Get-ChildItem -LiteralPath $Directory -Force)){
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw ('Link refused; not followed: '+$item.FullName)}
        $item
        if($item.PSIsContainer){Tree $item.FullName}
    }
}
$rows=@(foreach($item in (Get-ChildItem -LiteralPath $dist -Force)){
    $row=[ordered]@{Path=$item.FullName.Substring($root.Length+1);Kind=$(if($item.PSIsContainer){'Folder'}else{'File'});Bytes=0;GeneratedVerified=$false;DataFiles=@();Issues=@();SHA256=$null}
    try{
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Link refused; not followed.'}
        if($item.PSIsContainer){
            $tree=@(Tree $item.FullName);$files=@($tree|Where-Object {-not $_.PSIsContainer})
            $row.Bytes=[long]($files|Measure-Object Length -Sum).Sum
            $manifest=Get-Content -LiteralPath (Join-Path $item.FullName 'distribution-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
            foreach($entry in $manifest){
                $target=[IO.Path]::GetFullPath((Join-Path $item.FullName $entry.Path))
                if(-not $target.StartsWith($item.FullName+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe manifest path.'}
                if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.SHA256){throw ('Changed file: '+$entry.Path)}
            }
            $extra=@($files|Where-Object {$_.Name -ne 'distribution-manifest.json' -and $_.FullName.Substring($item.FullName.Length+1) -notin $manifest.Path})
            $row.DataFiles=@($files|Where-Object {$_.FullName.Substring($item.FullName.Length+1) -match '(^|\\)(Input|Output|Watermark)\\' -and $_.Name -ne '.gitkeep'}|ForEach-Object {$_.FullName.Substring($item.FullName.Length+1)})
            if($extra.Count){throw ('Unmanifested files: '+($extra.Name -join ', '))}
            $row.GeneratedVerified=$manifest.Count -gt 0 -and $row.DataFiles.Count -eq 0
        }elseif($item.Extension -eq '.zip'){
            $row.Bytes=$item.Length;$row.SHA256=(Get-FileHash -LiteralPath $item.FullName).Hash
            $zip=[IO.Compression.ZipFile]::OpenRead($item.FullName)
            try{
                $manifestEntry=$zip.GetEntry('distribution-manifest.json');if(-not $manifestEntry){throw 'No generated manifest.'}
                $reader=New-Object IO.StreamReader($manifestEntry.Open());try{$manifest=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
                foreach($entry in $manifest){
                    $z=$zip.GetEntry($entry.Path.Replace('\','/'));if(-not $z){throw ('Missing ZIP entry: '+$entry.Path)}
                    $stream=$z.Open();$sha=[Security.Cryptography.SHA256]::Create()
                    try{$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
                    if($hash -ne $entry.SHA256){throw ('Changed ZIP entry: '+$entry.Path)}
                }
                $extra=@($zip.Entries|Where-Object {$_.Name -and $_.FullName -ne 'distribution-manifest.json' -and $_.FullName.Replace('/','\') -notin $manifest.Path})
                $row.DataFiles=@($zip.Entries|Where-Object {$_.Name -and $_.FullName -match '(^|/)(Input|Output|Watermark)/' -and $_.Name -ne '.gitkeep'}|ForEach-Object FullName)
                if($extra.Count){throw 'Unmanifested ZIP entries.'}
                $row.GeneratedVerified=$manifest.Count -gt 0 -and $row.DataFiles.Count -eq 0
            }finally{$zip.Dispose()}
        }else{throw 'Unrecognized artifact; retained.'}
    }catch{$row.Issues=@($_.Exception.Message)}
    [pscustomobject]$row
})
if($Report){ConvertTo-Json -InputObject $rows -Depth 6|Set-Content -LiteralPath $Report -Encoding UTF8}
$rows|Select-Object Path,Kind,Bytes,GeneratedVerified,@{n='DataFiles';e={$_.DataFiles.Count}},@{n='Issues';e={$_.Issues -join '; '}}|Format-Table -AutoSize
# Inventory only. A valid generated manifest cannot establish that another backup
# exists. Nothing is removed; exact user consent remains necessary for cleanup.
