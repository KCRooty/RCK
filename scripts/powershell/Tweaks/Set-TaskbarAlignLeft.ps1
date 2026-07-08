#Requires -Version 7.0

$script:ExplorerAdvancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

function Test-TaskbarAlignedLeft {
    $value = Get-ItemProperty -Path $script:ExplorerAdvancedPath -Name 'TaskbarAl' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.TaskbarAl -eq 0)
}

function Invoke-ApplyTaskbarAlignLeft {
    New-Item -Path $script:ExplorerAdvancedPath -Force | Out-Null
    Set-ItemProperty -Path $script:ExplorerAdvancedPath -Name 'TaskbarAl' -Value 0 -Type DWord
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

function Invoke-RevertTaskbarAlignLeft {
    if (Test-Path $script:ExplorerAdvancedPath) {
        Set-ItemProperty -Path $script:ExplorerAdvancedPath -Name 'TaskbarAl' -Value 1 -Type DWord
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    }
}
