#Requires -Version 7.0

$script:GraphicsDriversPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'

function Test-HagsEnabled {
    $value = Get-ItemProperty -Path $script:GraphicsDriversPath -Name 'HwSchMode' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.HwSchMode -eq 2)
}

function Invoke-ApplyEnableHags {
    Set-ItemProperty -Path $script:GraphicsDriversPath -Name 'HwSchMode' -Value 2 -Type DWord
}

function Invoke-RevertEnableHags {
    Set-ItemProperty -Path $script:GraphicsDriversPath -Name 'HwSchMode' -Value 1 -Type DWord
}
