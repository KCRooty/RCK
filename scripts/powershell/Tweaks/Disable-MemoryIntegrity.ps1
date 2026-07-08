#Requires -Version 7.0

$script:HvciPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'

function Test-MemoryIntegrityDisabled {
    $value = Get-ItemProperty -Path $script:HvciPath -Name 'Enabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.Enabled -eq 0)
}

function Invoke-ApplyDisableMemoryIntegrity {
    New-Item -Path $script:HvciPath -Force | Out-Null
    Set-ItemProperty -Path $script:HvciPath -Name 'Enabled' -Value 0 -Type DWord
}

function Invoke-RevertDisableMemoryIntegrity {
    if (Test-Path $script:HvciPath) {
        Set-ItemProperty -Path $script:HvciPath -Name 'Enabled' -Value 1 -Type DWord
    }
}
