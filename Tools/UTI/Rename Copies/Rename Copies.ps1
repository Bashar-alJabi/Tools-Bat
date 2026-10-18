param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Rename Copies' $PSScriptRoot $Mode '' 'Copy files with ordered numeric names; originals are never renamed.'
    $null=Read-LocalChoice $Mode @('Number copies as 0001, 0002, ... and save a name map')
    $files=@(Get-SafeFiles $script:InputDir $null)
    Invoke-LocalBatch $files {'renamed'} {
        param($source,$result,$file,$all)
        $i=0;$rows=@(foreach($entry in $all){$i++;$name=('{0:D4}' -f $i)+$entry.Extension;[IO.File]::Copy($entry.FullName,(Join-Path $result $name),$false);[pscustomobject]@{Original=$entry.Name;Copy=$name}})
        $rows|Export-Csv -LiteralPath (Join-Path $result 'rename-map.csv') -NoTypeInformation -Encoding UTF8
    } -Aggregate -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
