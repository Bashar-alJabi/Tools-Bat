param([ValidateSet('Interactive','Defaults','Check','Help')][string]$Mode='Interactive')
. (Join-Path $PSScriptRoot '..\..\_shared\Core.ps1')
try {
    Show-LocalTool 'Network Info' $PSScriptRoot $Mode '' 'Read local network addresses, DNS servers and gateways; does not change configuration.'
    $null=Read-LocalChoice $Mode @('Save local adapter report')
    $destination=Join-Path $script:OutputDir 'network-info.json'
    if(Test-Path -LiteralPath $destination){Write-Host '[SKIPPED] network-info.json already exists.';exit 0}
    $rows=@(foreach($adapter in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()){
        $properties=$adapter.GetIPProperties()
        [pscustomobject]@{Name=$adapter.Name;Type=$adapter.NetworkInterfaceType.ToString();Status=$adapter.OperationalStatus.ToString();Addresses=@($properties.UnicastAddresses|ForEach-Object{$_.Address.ToString()});DNS=@($properties.DnsAddresses|ForEach-Object{$_.ToString()});Gateways=@($properties.GatewayAddresses|ForEach-Object{$_.Address.ToString()})}
    })
    $work=New-WorkDirectory $script:OutputDir
    try{$result=Join-Path $work 'report.json';ConvertTo-Json -InputObject $rows -Depth 5|Set-Content -LiteralPath $result -Encoding UTF8;Publish-File $result $destination}finally{Remove-WorkDirectory $work $script:OutputDir}
    Write-Host '[SUCCESS] network-info.json'
    exit 0
} catch {Write-Host ('[ERROR] '+$_.Exception.Message);exit 2}
