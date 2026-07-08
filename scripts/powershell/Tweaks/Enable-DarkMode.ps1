#Requires -Version 7.0

$script:PersonalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Test-DarkModeEnabled {
    $value = Get-ItemProperty -Path $script:PersonalizePath -Name 'AppsUseLightTheme' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.AppsUseLightTheme -eq 0)
}

function Invoke-ApplyEnableDarkMode {
    New-Item -Path $script:PersonalizePath -Force | Out-Null
    Set-ItemProperty -Path $script:PersonalizePath -Name 'AppsUseLightTheme' -Value 0 -Type DWord
    Set-ItemProperty -Path $script:PersonalizePath -Name 'SystemUsesLightTheme' -Value 0 -Type DWord
}

function Invoke-RevertEnableDarkMode {
    if (Test-Path $script:PersonalizePath) {
        Set-ItemProperty -Path $script:PersonalizePath -Name 'AppsUseLightTheme' -Value 1 -Type DWord
        Set-ItemProperty -Path $script:PersonalizePath -Name 'SystemUsesLightTheme' -Value 1 -Type DWord
    }
}
