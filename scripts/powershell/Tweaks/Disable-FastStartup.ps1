#Requires -Version 7.0

$script:PowerPolicyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'

function Test-FastStartupDisabled {
    $value = Get-ItemProperty -Path $script:PowerPolicyPath -Name 'HiberbootEnabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.HiberbootEnabled -eq 0)
}

function Invoke-ApplyDisableFastStartup {
    Set-ItemProperty -Path $script:PowerPolicyPath -Name 'HiberbootEnabled' -Value 0 -Type DWord
}

function Invoke-RevertDisableFastStartup {
    Set-ItemProperty -Path $script:PowerPolicyPath -Name 'HiberbootEnabled' -Value 1 -Type DWord
}
