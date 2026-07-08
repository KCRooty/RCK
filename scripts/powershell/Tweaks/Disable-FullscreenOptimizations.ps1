#Requires -Version 7.0

$script:GameConfigStorePath = 'HKCU:\System\GameConfigStore'

function Test-FullscreenOptimizationsDisabled {
    $value = Get-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.GameDVR_DXGIHonorFSEWindowsCompatible -eq 1)
}

function Invoke-ApplyDisableFullscreenOptimizations {
    New-Item -Path $script:GameConfigStorePath -Force | Out-Null
    Set-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 1 -Type DWord
    Set-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_HonorUserFSEBehaviorMode' -Value 1 -Type DWord
}

function Invoke-RevertDisableFullscreenOptimizations {
    if (Test-Path $script:GameConfigStorePath) {
        Remove-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $script:GameConfigStorePath -Name 'GameDVR_HonorUserFSEBehaviorMode' -ErrorAction SilentlyContinue
    }
}
