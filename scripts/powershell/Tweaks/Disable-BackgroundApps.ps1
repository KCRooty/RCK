#Requires -Version 7.0

$script:BackgroundAppsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'

function Test-BackgroundAppsDisabled {
    if (-not (Test-Path $script:BackgroundAppsPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:BackgroundAppsPath -Name 'GlobalUserDisabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.GlobalUserDisabled -eq 1)
}

function Invoke-ApplyDisableBackgroundApps {
    New-Item -Path $script:BackgroundAppsPath -Force | Out-Null
    Set-ItemProperty -Path $script:BackgroundAppsPath -Name 'GlobalUserDisabled' -Value 1 -Type DWord
}

function Invoke-RevertDisableBackgroundApps {
    if (Test-Path $script:BackgroundAppsPath) {
        Remove-ItemProperty -Path $script:BackgroundAppsPath -Name 'GlobalUserDisabled' -ErrorAction SilentlyContinue
    }
}
