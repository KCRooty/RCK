#Requires -Version 7.0

function Invoke-RunClearTempFiles {
    Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    Get-ChildItem -Path "$env:SystemRoot\Temp" -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
