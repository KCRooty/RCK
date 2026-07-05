#Requires -Version 7.0

$script:StorageSensePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'

function Test-StorageSenseDisabled {
    if (-not (Test-Path $script:StorageSensePath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:StorageSensePath -Name '01' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.'01' -eq 0)
}

function Invoke-ApplyDisableStorageSense {
    New-Item -Path $script:StorageSensePath -Force | Out-Null
    Set-ItemProperty -Path $script:StorageSensePath -Name '01' -Value 0 -Type DWord
}

function Invoke-RevertDisableStorageSense {
    if (Test-Path $script:StorageSensePath) {
        Set-ItemProperty -Path $script:StorageSensePath -Name '01' -Value 1 -Type DWord
    }
}
