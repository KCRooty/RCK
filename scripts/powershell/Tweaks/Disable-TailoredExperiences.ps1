#Requires -Version 7.0

$script:ContentDeliveryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$script:PrivacyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'
$script:SubscribedContentValues = @(
    'SubscribedContent-338388Enabled',
    'SubscribedContent-338389Enabled',
    'SubscribedContent-353694Enabled',
    'SubscribedContent-353696Enabled',
    'SystemPaneSuggestionsEnabled',
    'SoftLandingEnabled'
)

function Test-TailoredExperiencesDisabled {
    if (-not (Test-Path $script:PrivacyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:PrivacyPath -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.TailoredExperiencesWithDiagnosticDataEnabled -eq 0)
}

function Invoke-ApplyDisableTailoredExperiences {
    New-Item -Path $script:PrivacyPath -Force | Out-Null
    Set-ItemProperty -Path $script:PrivacyPath -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 -Type DWord

    New-Item -Path $script:ContentDeliveryPath -Force | Out-Null
    foreach ($name in $script:SubscribedContentValues) {
        Set-ItemProperty -Path $script:ContentDeliveryPath -Name $name -Value 0 -Type DWord
    }
}

function Invoke-RevertDisableTailoredExperiences {
    if (Test-Path $script:PrivacyPath) {
        Remove-ItemProperty -Path $script:PrivacyPath -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -ErrorAction SilentlyContinue
    }
    if (Test-Path $script:ContentDeliveryPath) {
        foreach ($name in $script:SubscribedContentValues) {
            Remove-ItemProperty -Path $script:ContentDeliveryPath -Name $name -ErrorAction SilentlyContinue
        }
    }
}
