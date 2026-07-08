#Requires -Version 7.0

$script:AppPrivacyPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
$script:AppPrivacyCapabilities = @(
    'LetAppsAccessLocation',
    'LetAppsAccessCamera',
    'LetAppsAccessMicrophone',
    'LetAppsAccessContacts',
    'LetAppsAccessCalendar',
    'LetAppsAccessCallHistory',
    'LetAppsAccessMessaging',
    'LetAppsAccessNotifications',
    'LetAppsAccessEmail',
    'LetAppsAccessTasks',
    'LetAppsAccessDiagnosticInfo',
    'LetAppsActivateWithVoiceAboveLock',
    'LetAppsAccessPhone',
    'LetAppsAccessTrustedDevices',
    'LetAppsAccessAccountInfo',
    'LetAppsAccessMotion',
    'LetAppsAccessRadios'
)

function Test-AppPermissionsRestricted {
    if (-not (Test-Path $script:AppPrivacyPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:AppPrivacyPolicyPath -Name 'LetAppsAccessLocation' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.LetAppsAccessLocation -eq 2)
}

function Invoke-ApplyRestrictAppPermissions {
    New-Item -Path $script:AppPrivacyPolicyPath -Force | Out-Null
    foreach ($name in $script:AppPrivacyCapabilities) {
        # 2 = Force Deny (política "Deny" para todas las apps)
        Set-ItemProperty -Path $script:AppPrivacyPolicyPath -Name $name -Value 2 -Type DWord
    }
}

function Invoke-RevertRestrictAppPermissions {
    if (Test-Path $script:AppPrivacyPolicyPath) {
        foreach ($name in $script:AppPrivacyCapabilities) {
            Remove-ItemProperty -Path $script:AppPrivacyPolicyPath -Name $name -ErrorAction SilentlyContinue
        }
    }
}
