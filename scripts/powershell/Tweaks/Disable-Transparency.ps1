#Requires -Version 7.0

$script:PersonalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Test-TransparencyDisabled {
    $value = Get-ItemProperty -Path $script:PersonalizePath -Name 'EnableTransparency' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.EnableTransparency -eq 0)
}

function Invoke-ApplyDisableTransparency {
    New-Item -Path $script:PersonalizePath -Force | Out-Null
    Set-ItemProperty -Path $script:PersonalizePath -Name 'EnableTransparency' -Value 0 -Type DWord
}

function Invoke-RevertDisableTransparency {
    if (Test-Path $script:PersonalizePath) {
        Set-ItemProperty -Path $script:PersonalizePath -Name 'EnableTransparency' -Value 1 -Type DWord
    }
}
