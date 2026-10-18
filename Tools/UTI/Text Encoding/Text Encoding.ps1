param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Text Encoding' $PSScriptRoot $Mode '' 'Convert strictly validated UTF-8 or BOM-marked UTF-16 text to UTF-8.'
    $choice=Read-LocalChoice $Mode @('UTF-8 without BOM','UTF-8 with BOM')
    $files=@(Get-SafeFiles $script:InputDir @('.txt','.csv','.json','.xml','.md','.srt','.vtt','.log','.ini','.yaml','.yml'))
    Invoke-LocalBatch $files {param($f) $f.Name+'.utf8'+$f.Extension} {
        param($source,$result)
        if((Get-Item -LiteralPath $source).Length -gt 32MB){throw 'Text conversion limit is 32 MB per file.'}
        $bytes=[IO.File]::ReadAllBytes($source);$offset=0
        if($bytes.Length -ge 4 -and (($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 254 -and $bytes[3] -eq 255) -or ($bytes[0] -eq 255 -and $bytes[1] -eq 254 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0))){throw 'UTF-32 is not supported.'}
        if($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254){$encoding=New-Object Text.UnicodeEncoding($false,$true,$true);$offset=2}
        elseif($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255){$encoding=New-Object Text.UnicodeEncoding($true,$true,$true);$offset=2}
        else{$encoding=New-Object Text.UTF8Encoding($false,$true);if($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191){$offset=3}}
        $text=$encoding.GetString($bytes,$offset,($bytes.Length-$offset))
        if($text.IndexOf([char]0) -ge 0){throw 'NUL characters suggest binary text or UTF-16 without a BOM; refused.'}
        # A BOM is optional; empty text is represented by a UTF-8 BOM to retain a real output file.
        [IO.File]::WriteAllText($result,$text,(New-Object Text.UTF8Encoding(($choice -eq 2 -or $text.Length -eq 0))))
    }
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
