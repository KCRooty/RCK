#Requires -Version 7.0

function Invoke-RunFlushIconCache {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    $iconCacheDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Explorer'
    Get-ChildItem -Path $iconCacheDir -Filter 'iconcache*' -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Start-Process explorer.exe
}
