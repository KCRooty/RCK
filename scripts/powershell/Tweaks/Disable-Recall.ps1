#Requires -Version 7.0

$script:RecallPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'

function Test-RecallDisabled {
    if (-not (Test-Path $script:RecallPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:RecallPolicyPath -Name 'DisableAIDataAnalysis' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DisableAIDataAnalysis -eq 1)
}

function Invoke-ApplyDisableRecall {
    New-Item -Path $script:RecallPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:RecallPolicyPath -Name 'DisableAIDataAnalysis' -Value 1 -Type DWord
    Set-ItemProperty -Path $script:RecallPolicyPath -Name 'AllowRecallEnablement' -Value 0 -Type DWord
}

function Invoke-RevertDisableRecall {
    if (Test-Path $script:RecallPolicyPath) {
        Remove-ItemProperty -Path $script:RecallPolicyPath -Name 'DisableAIDataAnalysis' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:RecallPolicyPath -Name 'AllowRecallEnablement' -ErrorAction SilentlyContinue
    }
}
