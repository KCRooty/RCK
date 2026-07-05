#Requires -Version 7.0

$script:TelemetryPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

function Test-DisableTelemetryStatus {
    if (-not (Test-Path $script:TelemetryPolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:TelemetryPolicyPath -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.AllowTelemetry -le 1)
}

function Invoke-ApplyDisableTelemetry {
    New-Item -Path $script:TelemetryPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:TelemetryPolicyPath -Name 'AllowTelemetry' -Value 0 -Type DWord
    Set-Service -Name 'DiagTrack' -StartupType Manual -ErrorAction SilentlyContinue
}

function Invoke-RevertDisableTelemetry {
    if (Test-Path $script:TelemetryPolicyPath) {
        Remove-ItemProperty -Path $script:TelemetryPolicyPath -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    }
    Set-Service -Name 'DiagTrack' -StartupType Automatic -ErrorAction SilentlyContinue
}
