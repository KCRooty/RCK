#Requires -Version 7.0

function Test-WakeTimersDisabled {
    $output = powercfg /query SCHEME_CURRENT SUB_SLEEP RTCWAKE
    $acLine = $output | Select-String 'Current AC Power Setting Index:\s*0x0+$'
    return [bool]$acLine
}

function Invoke-ApplyDisableWakeTimers {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
    powercfg /setactive SCHEME_CURRENT
}

function Invoke-RevertDisableWakeTimers {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
    powercfg /setactive SCHEME_CURRENT
}
