#Requires -Version 7.0

$script:PersonalizationPath = 'HKCU:\Software\Microsoft\Personalization\Settings'
$script:InputPersonalizationPath = 'HKCU:\Software\Microsoft\InputPersonalization'

function Test-WindowsInkDisabled {
    $value = Get-ItemProperty -Path $script:PersonalizationPath -Name 'AcceptedPrivacyPolicy' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.AcceptedPrivacyPolicy -eq 0)
}

function Invoke-ApplyDisableWindowsInk {
    New-Item -Path $script:PersonalizationPath -Force | Out-Null
    Set-ItemProperty -Path $script:PersonalizationPath -Name 'AcceptedPrivacyPolicy' -Value 0 -Type DWord

    New-Item -Path $script:InputPersonalizationPath -Force | Out-Null
    Set-ItemProperty -Path $script:InputPersonalizationPath -Name 'RestrictImplicitInkCollection' -Value 1 -Type DWord
    Set-ItemProperty -Path $script:InputPersonalizationPath -Name 'RestrictImplicitTextCollection' -Value 1 -Type DWord
}

function Invoke-RevertDisableWindowsInk {
    if (Test-Path $script:PersonalizationPath) {
        Remove-ItemProperty -Path $script:PersonalizationPath -Name 'AcceptedPrivacyPolicy' -ErrorAction SilentlyContinue
    }
    if (Test-Path $script:InputPersonalizationPath) {
        Remove-ItemProperty -Path $script:InputPersonalizationPath -Name 'RestrictImplicitInkCollection' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:InputPersonalizationPath -Name 'RestrictImplicitTextCollection' -ErrorAction SilentlyContinue
    }
}
