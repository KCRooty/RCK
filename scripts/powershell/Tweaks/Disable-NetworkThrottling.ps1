#Requires -Version 7.0

$script:ProfilePath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'

function Test-NetworkThrottlingDisabled {
    $value = Get-ItemProperty -Path $script:ProfilePath -Name 'NetworkThrottlingIndex' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.NetworkThrottlingIndex -eq 0xFFFFFFFF)
}

function Invoke-ApplyDisableNetworkThrottling {
    Set-ItemProperty -Path $script:ProfilePath -Name 'NetworkThrottlingIndex' -Value 0xFFFFFFFF -Type DWord
    Set-ItemProperty -Path $script:ProfilePath -Name 'SystemResponsiveness' -Value 0 -Type DWord
}

function Invoke-RevertDisableNetworkThrottling {
    Set-ItemProperty -Path $script:ProfilePath -Name 'NetworkThrottlingIndex' -Value 10 -Type DWord
    Set-ItemProperty -Path $script:ProfilePath -Name 'SystemResponsiveness' -Value 20 -Type DWord
}
