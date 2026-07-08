#Requires -Version 7.0

$script:IfeoRoot = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
$script:GameExecutables = @(
    'cs2.exe', 'csgo.exe', 'valorant.exe', 'VALORANT-Win64-Shipping.exe',
    'FortniteClient-Win64-Shipping.exe', 'GTA5.exe', 'RDR2.exe',
    'EldenRing.exe', 'Minecraft.Windows.exe', 'minecraft.exe',
    'Overwatch.exe', 'ForzaHorizon5.exe', 'HaloInfinite.exe',
    'Battlefield2042.exe', 'Cyberpunk2077.exe', 'HogwartsLegacy.exe'
)
# CpuPriorityClass = 6 -> "High" (ver PROCESS_PRIORITY_CLASS de Win32)
$script:HighPriority = 6

function Test-GamePriorityBoosted {
    foreach ($exe in $script:GameExecutables) {
        $path = Join-Path $script:IfeoRoot "$exe\PerfOptions"
        $value = Get-ItemProperty -Path $path -Name 'CpuPriorityClass' -ErrorAction SilentlyContinue
        if (-not $value -or $value.CpuPriorityClass -ne $script:HighPriority) {
            return $false
        }
    }
    return $true
}

function Invoke-ApplyBoostGamePriority {
    foreach ($exe in $script:GameExecutables) {
        $path = Join-Path $script:IfeoRoot "$exe\PerfOptions"
        New-Item -Path $path -Force | Out-Null
        Set-ItemProperty -Path $path -Name 'CpuPriorityClass' -Value $script:HighPriority -Type DWord
    }
}

function Invoke-RevertBoostGamePriority {
    foreach ($exe in $script:GameExecutables) {
        $path = Join-Path $script:IfeoRoot "$exe\PerfOptions"
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name 'CpuPriorityClass' -ErrorAction SilentlyContinue
        }
    }
}
