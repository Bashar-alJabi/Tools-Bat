param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\..\System\Shared\Core.ps1')
try {
    Show-LocalTool 'Ping Host' $PSScriptRoot $Mode '' 'Four ICMP echo requests to a host or IP; defaults to local loopback. No network settings change.'
    $choice=Read-LocalChoice $Mode @('Local loopback 127.0.0.1','Custom host or IP')
    $target='127.0.0.1'
    if($choice -eq 2){$target=Read-Host 'Hostname or IP only (no URL, port, switches or spaces)'}
    if($target.Length -gt 253 -or $target -match '(^-|[^a-zA-Z0-9.:-])' -or [uri]::CheckHostName($target) -eq [UriHostNameType]::Unknown){throw 'Invalid hostname or IP address.'}
    $destination=Join-Path $script:OutputDir 'ping.csv'
    if(Test-Path -LiteralPath $destination){Write-Host '[SKIPPED] ping.csv already exists.';exit 0}
    $client=New-Object Net.NetworkInformation.Ping;$rows=@()
    try {
        for($i=1;$i -le 4;$i++){
            try{$reply=$client.Send($target,1000);$rows+=[pscustomobject]@{Attempt=$i;Target=$target;Status=$reply.Status.ToString();Milliseconds=$reply.RoundtripTime;ErrorDetail=''}}
            catch{$reason=$_.Exception;while($reason.InnerException){$reason=$reason.InnerException};$rows+=[pscustomobject]@{Attempt=$i;Target=$target;Status='Error';Milliseconds='';ErrorDetail=$reason.Message}}
        }
    }finally{$client.Dispose()}
    $work=New-WorkDirectory $script:OutputDir
    try{$result=Join-Path $work 'report.csv';$rows|Export-Csv -LiteralPath $result -NoTypeInformation -Encoding UTF8;Publish-File $result $destination}finally{Remove-WorkDirectory $work $script:OutputDir}
    if(@($rows|Where-Object Status -eq 'Success').Count){Write-Host '[SUCCESS] ping.csv';exit 0}
    Write-Host '[FAILED] No replies. The report was saved; ICMP may be blocked.';exit 1
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
