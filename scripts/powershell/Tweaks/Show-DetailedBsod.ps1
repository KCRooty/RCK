#Requires -Version 7.0

$script:CrashControlPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'

function Test-DetailedBsodEnabled {
    $value = Get-ItemProperty -Path $script:CrashControlPath -Name 'DisplayParameters' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DisplayParameters -eq 1)
}

function Invoke-ApplyShowDetailedBsod {
    Set-ItemProperty -Path $script:CrashControlPath -Name 'DisplayParameters' -Value 1 -Type DWord
}

function Invoke-RevertShowDetailedBsod {
    Set-ItemProperty -Path $script:CrashControlPath -Name 'DisplayParameters' -Value 0 -Type DWord
}
