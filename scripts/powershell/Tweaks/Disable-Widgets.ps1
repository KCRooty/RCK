#Requires -Version 7.0

$script:WidgetsPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'

function Test-WidgetsDisabled {
    if (-not (Test-Path $script:WidgetsPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:WidgetsPolicyPath -Name 'AllowNewsAndInterests' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.AllowNewsAndInterests -eq 0)
}

function Invoke-ApplyDisableWidgets {
    New-Item -Path $script:WidgetsPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:WidgetsPolicyPath -Name 'AllowNewsAndInterests' -Value 0 -Type DWord
}

function Invoke-RevertDisableWidgets {
    if (Test-Path $script:WidgetsPolicyPath) {
        Remove-ItemProperty -Path $script:WidgetsPolicyPath -Name 'AllowNewsAndInterests' -ErrorAction SilentlyContinue
    }
}
