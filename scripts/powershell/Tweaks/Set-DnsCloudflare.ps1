#Requires -Version 7.0

$script:CloudflareDns = @('1.1.1.1', '1.0.0.1')

function Get-ActiveAdapters {
    Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
}

function Test-DnsCloudflareSet {
    $adapters = Get-ActiveAdapters
    if (-not $adapters) {
        return $false
    }
    foreach ($adapter in $adapters) {
        $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if (-not $dns -or (Compare-Object $dns.ServerAddresses $script:CloudflareDns)) {
            return $false
        }
    }
    return $true
}

function Invoke-ApplySetDnsCloudflare {
    foreach ($adapter in Get-ActiveAdapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $script:CloudflareDns -ErrorAction SilentlyContinue
    }
}

function Invoke-RevertSetDnsCloudflare {
    foreach ($adapter in Get-ActiveAdapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
}
