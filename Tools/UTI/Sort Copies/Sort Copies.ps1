param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Sort Copies' $PSScriptRoot $Mode '' 'Organize copies of flat Input files by extension; originals stay in Input.'
    $null=Read-LocalChoice $Mode @('Sort copies by extension')
    $files=@(Get-SafeFiles $script:InputDir $null)
    Invoke-LocalBatch $files {'sorted'} {
        param($source,$result,$file,$all)
        foreach($entry in $all){
            $extension=$entry.Extension.TrimStart('.').ToLowerInvariant()
            # Prefix makes reserved device names such as .con safe folder names.
            $folder=if($extension){'ext-'+$extension}else{'no-extension'}
            $dir=Join-Path $result $folder;Ensure-Directory $dir
            [IO.File]::Copy($entry.FullName,(Join-Path $dir $entry.Name),$false)
        }
    } -Aggregate -DirectoryResult
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
