#Requires -Version 7.0

$script:MousePath = 'HKCU:\Control Panel\Mouse'

function Test-MouseAccelerationDisabled {
    $value = Get-ItemProperty -Path $script:MousePath -Name 'MouseSpeed' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.MouseSpeed -eq '0')
}

function Invoke-ApplyDisableMouseAcceleration {
    Set-ItemProperty -Path $script:MousePath -Name 'MouseSpeed' -Value '0' -Type String
    Set-ItemProperty -Path $script:MousePath -Name 'MouseThreshold1' -Value '0' -Type String
    Set-ItemProperty -Path $script:MousePath -Name 'MouseThreshold2' -Value '0' -Type String
}

function Invoke-RevertDisableMouseAcceleration {
    Set-ItemProperty -Path $script:MousePath -Name 'MouseSpeed' -Value '1' -Type String
    Set-ItemProperty -Path $script:MousePath -Name 'MouseThreshold1' -Value '6' -Type String
    Set-ItemProperty -Path $script:MousePath -Name 'MouseThreshold2' -Value '10' -Type String
}
