param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Folder Compare' $PSScriptRoot $Mode '' 'Compare Input\Left and Input\Right recursively by relative name and SHA-256; report only.'
    $null=Read-LocalChoice $Mode @('Compare two folders without changing either')
    $left=Join-Path $script:InputDir 'Left';$right=Join-Path $script:InputDir 'Right'
    if(-not [IO.Directory]::Exists($left) -or -not [IO.Directory]::Exists($right)){throw 'Create Input\Left and Input\Right and place files in them.'}
    Ensure-Directory $left;Ensure-Directory $right
    $a=@{};$b=@{}
    foreach($file in (Get-SafeFiles $left $null -Recurse)){$a[(Get-RelativeName $left $file.FullName)]=$file}
    foreach($file in (Get-SafeFiles $right $null -Recurse)){$b[(Get-RelativeName $right $file.FullName)]=$file}
    $files=@(Get-SafeFiles $script:InputDir $null -Recurse)
    Invoke-LocalBatch $files {'comparison.csv'} {
        param($source,$result)
        $rows=@(foreach($key in (@($a.Keys)+@($b.Keys)|Sort-Object -Unique)){
            $status=if(-not $a.ContainsKey($key)){'RightOnly'}elseif(-not $b.ContainsKey($key)){'LeftOnly'}elseif($a[$key].Length -ne $b[$key].Length){'Different'}elseif((Get-FileHash -LiteralPath $a[$key].FullName).Hash -ne (Get-FileHash -LiteralPath $b[$key].FullName).Hash){'Different'}else{'Identical'}
            [pscustomobject]@{Path=$key;Status=$status}
        })
        $rows|Export-Csv -LiteralPath $result -NoTypeInformation -Encoding UTF8
    } -Aggregate
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
