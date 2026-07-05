#Requires -Version 7.0

$script:AdvertisingIdPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'

function Test-AdvertisingIdDisabled {
    if (-not (Test-Path $script:AdvertisingIdPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:AdvertisingIdPath -Name 'Enabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.Enabled -eq 0)
}

function Invoke-ApplyDisableAdvertisingId {
    New-Item -Path $script:AdvertisingIdPath -Force | Out-Null
    Set-ItemProperty -Path $script:AdvertisingIdPath -Name 'Enabled' -Value 0 -Type DWord
}

function Invoke-RevertDisableAdvertisingId {
    if (Test-Path $script:AdvertisingIdPath) {
        Set-ItemProperty -Path $script:AdvertisingIdPath -Name 'Enabled' -Value 1 -Type DWord
    }
}
