#Requires -Version 7.0

$script:PowerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'

function Test-HibernationDisabled {
    $value = Get-ItemProperty -Path $script:PowerPath -Name 'HibernateEnabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.HibernateEnabled -eq 0)
}

function Invoke-ApplyDisableHibernation {
    powercfg /hibernate off
}

function Invoke-RevertDisableHibernation {
    powercfg /hibernate on
}
