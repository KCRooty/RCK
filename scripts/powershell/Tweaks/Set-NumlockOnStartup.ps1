#Requires -Version 7.0

$script:DefaultKeyboardPath = 'HKU:\.DEFAULT\Control Panel\Keyboard'

function Ensure-HkuDrive {
    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null
    }
}

function Test-NumlockOnStartupEnabled {
    Ensure-HkuDrive
    $value = Get-ItemProperty -Path $script:DefaultKeyboardPath -Name 'InitialKeyboardIndicators' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.InitialKeyboardIndicators -eq '2')
}

function Invoke-ApplyNumlockOnStartup {
    Ensure-HkuDrive
    Set-ItemProperty -Path $script:DefaultKeyboardPath -Name 'InitialKeyboardIndicators' -Value '2' -Type String
}

function Invoke-RevertNumlockOnStartup {
    Ensure-HkuDrive
    if (Test-Path $script:DefaultKeyboardPath) {
        Set-ItemProperty -Path $script:DefaultKeyboardPath -Name 'InitialKeyboardIndicators' -Value '0' -Type String
    }
}
