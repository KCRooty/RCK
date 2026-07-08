#Requires -Version 7.0

$script:AdvancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

function Test-SnapFlyoutDisabled {
    $value = Get-ItemProperty -Path $script:AdvancedPath -Name 'EnableSnapAssistFlyout' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.EnableSnapAssistFlyout -eq 0)
}

function Invoke-ApplyDisableSnapFlyout {
    New-Item -Path $script:AdvancedPath -Force | Out-Null
    Set-ItemProperty -Path $script:AdvancedPath -Name 'EnableSnapAssistFlyout' -Value 0 -Type DWord
}

function Invoke-RevertDisableSnapFlyout {
    if (Test-Path $script:AdvancedPath) {
        Set-ItemProperty -Path $script:AdvancedPath -Name 'EnableSnapAssistFlyout' -Value 1 -Type DWord
    }
}
