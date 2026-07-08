#Requires -Version 7.0

$script:SearchPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'

function Test-TaskbarSearchBoxHidden {
    $value = Get-ItemProperty -Path $script:SearchPath -Name 'SearchboxTaskbarMode' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.SearchboxTaskbarMode -eq 1)
}

function Invoke-ApplyHideTaskbarSearchBox {
    New-Item -Path $script:SearchPath -Force | Out-Null
    Set-ItemProperty -Path $script:SearchPath -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord
}

function Invoke-RevertHideTaskbarSearchBox {
    if (Test-Path $script:SearchPath) {
        Set-ItemProperty -Path $script:SearchPath -Name 'SearchboxTaskbarMode' -Value 2 -Type DWord
    }
}
