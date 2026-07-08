#Requires -Version 7.0

$script:NonEssentialServices = @('Fax', 'RemoteRegistry', 'MapsBroker', 'WalletService', 'RetailDemo')

function Test-NonEssentialManualSet {
    foreach ($name in $script:NonEssentialServices) {
        $service = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($service -and $service.StartType -ne 'Manual') {
            return $false
        }
    }
    return $true
}

function Invoke-ApplySetNonEssentialManual {
    foreach ($name in $script:NonEssentialServices) {
        Set-Service -Name $name -StartupType Manual -ErrorAction SilentlyContinue
    }
}

function Invoke-RevertSetNonEssentialManual {
    foreach ($name in $script:NonEssentialServices) {
        Set-Service -Name $name -StartupType Automatic -ErrorAction SilentlyContinue
    }
}
