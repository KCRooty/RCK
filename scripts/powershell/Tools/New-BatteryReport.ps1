#Requires -Version 7.0

function Invoke-RunGenerateBatteryReport {
    $reportPath = Join-Path $env:TEMP 'rck-battery-report.html'
    powercfg /batteryreport /output $reportPath | Out-Null
    if (Test-Path $reportPath) {
        Start-Process $reportPath
    }
}
