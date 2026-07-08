#Requires -Version 7.0

$script:GameConfigStorePath = 'HKCU:\System\GameConfigStore'
$script:GameBarPolicyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'
$script:GameModePath = 'HKCU:\Software\Microsoft\GameBar'

# Deshabilita Game DVR y fuerza el comportamiento de Fullscreen
# Optimizations (FSE) — mismos valores que un fix de FSO probado en juegos
# reales (Fortnite y similares): sin captura de fondo, sin "optimizaciones"
# que en la práctica introducen microstutter en modo pantalla completa
# exclusiva.
$script:GameConfigStoreValues = @{
    GameDVR_Enabled                          = 0
    GameDVR_FSEBehaviorMode                  = 2
    GameDVR_FSEBehavior                      = 2
    GameDVR_HonorUserFSEBehaviorMode         = 1
    GameDVR_DXGIHonorFSEWindowsCompatible    = 1
    GameDVR_EFSEFeatureFlags                 = 0
    GameDVR_DSEBehavior                      = 2
}

function Test-GamingModeEnabled {
    $value = Get-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_Enabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.GameDVR_Enabled -eq 0)
}

function Invoke-ApplyGamingMode {
    New-Item -Path $script:GameConfigStorePath -Force | Out-Null
    foreach ($name in $script:GameConfigStoreValues.Keys) {
        Set-ItemProperty -Path $script:GameConfigStorePath -Name $name -Value $script:GameConfigStoreValues[$name] -Type DWord
    }

    New-Item -Path $script:GameBarPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:GameBarPolicyPath -Name 'AppCaptureEnabled' -Value 0 -Type DWord

    New-Item -Path $script:GameModePath -Force | Out-Null
    Set-ItemProperty -Path $script:GameModePath -Name 'AutoGameModeEnabled' -Value 1 -Type DWord
}

function Invoke-RevertGamingMode {
    if (Test-Path $script:GameConfigStorePath) {
        Set-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_Enabled' -Value 1 -Type DWord
        foreach ($name in @('GameDVR_FSEBehaviorMode', 'GameDVR_FSEBehavior', 'GameDVR_HonorUserFSEBehaviorMode', 'GameDVR_DXGIHonorFSEWindowsCompatible', 'GameDVR_EFSEFeatureFlags', 'GameDVR_DSEBehavior')) {
            Remove-ItemProperty -Path $script:GameConfigStorePath -Name $name -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path $script:GameBarPolicyPath) {
        Set-ItemProperty -Path $script:GameBarPolicyPath -Name 'AppCaptureEnabled' -Value 1 -Type DWord
    }
}
