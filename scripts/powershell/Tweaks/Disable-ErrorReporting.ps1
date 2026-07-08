#Requires -Version 7.0

$script:WerPath = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'

function Test-ErrorReportingDisabled {
    $value = Get-ItemProperty -Path $script:WerPath -Name 'Disabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.Disabled -eq 1)
}

function Invoke-ApplyDisableErrorReporting {
    New-Item -Path $script:WerPath -Force | Out-Null
    Set-ItemProperty -Path $script:WerPath -Name 'Disabled' -Value 1 -Type DWord
}

function Invoke-RevertDisableErrorReporting {
    if (Test-Path $script:WerPath) {
        Remove-ItemProperty -Path $script:WerPath -Name 'Disabled' -ErrorAction SilentlyContinue
    }
}
