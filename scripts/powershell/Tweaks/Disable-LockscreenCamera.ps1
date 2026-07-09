#Requires -Version 7.0

$script:PersonalizationPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'

function Test-LockscreenCameraDisabled {
    if (-not (Test-Path $script:PersonalizationPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:PersonalizationPolicyPath -Name 'NoLockScreenCamera' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.NoLockScreenCamera -eq 1)
}

function Invoke-ApplyDisableLockscreenCamera {
    New-Item -Path $script:PersonalizationPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:PersonalizationPolicyPath -Name 'NoLockScreenCamera' -Value 1 -Type DWord
}

function Invoke-RevertDisableLockscreenCamera {
    if (Test-Path $script:PersonalizationPolicyPath) {
        Remove-ItemProperty -Path $script:PersonalizationPolicyPath -Name 'NoLockScreenCamera' -ErrorAction SilentlyContinue
    }
}
