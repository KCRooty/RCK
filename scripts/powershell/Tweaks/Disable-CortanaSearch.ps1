#Requires -Version 7.0

$script:SearchPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'

function Test-CortanaSearchDisabled {
    if (-not (Test-Path $script:SearchPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:SearchPolicyPath -Name 'AllowCortana' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.AllowCortana -eq 0)
}

function Invoke-ApplyDisableCortanaSearch {
    New-Item -Path $script:SearchPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:SearchPolicyPath -Name 'AllowCortana' -Value 0 -Type DWord
    Set-ItemProperty -Path $script:SearchPolicyPath -Name 'DisableWebSearch' -Value 1 -Type DWord
}

function Invoke-RevertDisableCortanaSearch {
    if (Test-Path $script:SearchPolicyPath) {
        Remove-ItemProperty -Path $script:SearchPolicyPath -Name 'AllowCortana' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:SearchPolicyPath -Name 'DisableWebSearch' -ErrorAction SilentlyContinue
    }
}
