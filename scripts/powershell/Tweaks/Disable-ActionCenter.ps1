#Requires -Version 7.0

$script:ExplorerPolicyPath = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'

function Test-ActionCenterDisabled {
    if (-not (Test-Path $script:ExplorerPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:ExplorerPolicyPath -Name 'DisableNotificationCenter' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DisableNotificationCenter -eq 1)
}

function Invoke-ApplyDisableActionCenter {
    New-Item -Path $script:ExplorerPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:ExplorerPolicyPath -Name 'DisableNotificationCenter' -Value 1 -Type DWord
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

function Invoke-RevertDisableActionCenter {
    if (Test-Path $script:ExplorerPolicyPath) {
        Remove-ItemProperty -Path $script:ExplorerPolicyPath -Name 'DisableNotificationCenter' -ErrorAction SilentlyContinue
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    }
}
