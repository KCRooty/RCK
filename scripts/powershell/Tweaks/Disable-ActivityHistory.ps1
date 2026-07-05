#Requires -Version 7.0

$script:ActivityHistoryPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'

function Test-ActivityHistoryDisabled {
    if (-not (Test-Path $script:ActivityHistoryPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:ActivityHistoryPolicyPath -Name 'EnableActivityFeed' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.EnableActivityFeed -eq 0)
}

function Invoke-ApplyDisableActivityHistory {
    New-Item -Path $script:ActivityHistoryPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:ActivityHistoryPolicyPath -Name 'EnableActivityFeed' -Value 0 -Type DWord
    Set-ItemProperty -Path $script:ActivityHistoryPolicyPath -Name 'PublishUserActivities' -Value 0 -Type DWord
    Set-ItemProperty -Path $script:ActivityHistoryPolicyPath -Name 'UploadUserActivities' -Value 0 -Type DWord
}

function Invoke-RevertDisableActivityHistory {
    foreach ($name in @('EnableActivityFeed', 'PublishUserActivities', 'UploadUserActivities')) {
        Remove-ItemProperty -Path $script:ActivityHistoryPolicyPath -Name $name -ErrorAction SilentlyContinue
    }
}
