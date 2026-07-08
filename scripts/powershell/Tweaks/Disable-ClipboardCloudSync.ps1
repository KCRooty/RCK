#Requires -Version 7.0

$script:ActivityFeedPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
$script:ClipboardUserPath = 'HKCU:\Software\Microsoft\Clipboard'

function Test-ClipboardCloudSyncDisabled {
    if (-not (Test-Path $script:ActivityFeedPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'EnableActivityFeed' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.EnableActivityFeed -eq 0)
}

function Invoke-ApplyDisableClipboardCloudSync {
    New-Item -Path $script:ActivityFeedPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'EnableActivityFeed' -Value 0 -Type DWord
    Set-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'PublishUserActivities' -Value 0 -Type DWord
    Set-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'UploadUserActivities' -Value 0 -Type DWord

    New-Item -Path $script:ClipboardUserPath -Force | Out-Null
    Set-ItemProperty -Path $script:ClipboardUserPath -Name 'EnableCloudClipboard' -Value 0 -Type DWord
}

function Invoke-RevertDisableClipboardCloudSync {
    if (Test-Path $script:ActivityFeedPolicyPath) {
        Remove-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'EnableActivityFeed' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'PublishUserActivities' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:ActivityFeedPolicyPath -Name 'UploadUserActivities' -ErrorAction SilentlyContinue
    }
    if (Test-Path $script:ClipboardUserPath) {
        Remove-ItemProperty -Path $script:ClipboardUserPath -Name 'EnableCloudClipboard' -ErrorAction SilentlyContinue
    }
}
