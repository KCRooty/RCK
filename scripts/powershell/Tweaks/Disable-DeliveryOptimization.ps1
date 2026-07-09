#Requires -Version 7.0

$script:DoPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'

function Test-DeliveryOptimizationDisabled {
    if (-not (Test-Path $script:DoPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:DoPolicyPath -Name 'DODownloadMode' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DODownloadMode -eq 0)
}

function Invoke-ApplyDisableDeliveryOptimization {
    New-Item -Path $script:DoPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:DoPolicyPath -Name 'DODownloadMode' -Value 0 -Type DWord
}

function Invoke-RevertDisableDeliveryOptimization {
    if (Test-Path $script:DoPolicyPath) {
        Remove-ItemProperty -Path $script:DoPolicyPath -Name 'DODownloadMode' -ErrorAction SilentlyContinue
    }
}
