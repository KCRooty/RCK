#Requires -Version 7.0

$script:CopilotPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'

function Test-CopilotDisabled {
    if (-not (Test-Path $script:CopilotPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:CopilotPolicyPath -Name 'TurnOffWindowsCopilot' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.TurnOffWindowsCopilot -eq 1)
}

function Invoke-ApplyRemoveCopilot {
    New-Item -Path $script:CopilotPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:CopilotPolicyPath -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
}

function Invoke-RevertRemoveCopilot {
    if (Test-Path $script:CopilotPolicyPath) {
        Remove-ItemProperty -Path $script:CopilotPolicyPath -Name 'TurnOffWindowsCopilot' -ErrorAction SilentlyContinue
    }
}
