#Requires -Version 7.0

$script:UltimatePerformanceGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$script:BalancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'

function Test-UltimatePerformancePlanActive {
    $active = powercfg /getactivescheme
    return $active -match $script:UltimatePerformanceGuid
}

function Invoke-ApplyEnableUltimatePerformancePlan {
    $existing = powercfg /list | Select-String $script:UltimatePerformanceGuid
    if (-not $existing) {
        powercfg -duplicatescheme $script:UltimatePerformanceGuid | Out-Null
    }
    powercfg /setactive $script:UltimatePerformanceGuid
}

function Invoke-RevertEnableUltimatePerformancePlan {
    powercfg /setactive $script:BalancedGuid
}
