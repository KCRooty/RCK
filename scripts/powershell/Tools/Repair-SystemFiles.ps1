#Requires -Version 7.0

function Invoke-RunSfcScan {
    sfc /scannow
}

function Invoke-RunDismRestoreHealth {
    DISM /Online /Cleanup-Image /RestoreHealth
}
