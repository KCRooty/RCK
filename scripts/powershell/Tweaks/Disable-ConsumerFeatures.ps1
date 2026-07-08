#Requires -Version 7.0

$script:CloudContentPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'

function Test-ConsumerFeaturesDisabled {
    if (-not (Test-Path $script:CloudContentPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableWindowsConsumerFeatures' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DisableWindowsConsumerFeatures -eq 1)
}

function Invoke-ApplyDisableConsumerFeatures {
    New-Item -Path $script:CloudContentPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableWindowsConsumerFeatures' -Value 1 -Type DWord
    Set-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableConsumerAccountStateContent' -Value 1 -Type DWord
    Set-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableCloudOptimizedContent' -Value 1 -Type DWord
}

function Invoke-RevertDisableConsumerFeatures {
    if (Test-Path $script:CloudContentPolicyPath) {
        Remove-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableWindowsConsumerFeatures' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableConsumerAccountStateContent' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:CloudContentPolicyPath -Name 'DisableCloudOptimizedContent' -ErrorAction SilentlyContinue
    }
}
