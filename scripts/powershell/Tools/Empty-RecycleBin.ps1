#Requires -Version 7.0

function Invoke-RunEmptyRecycleBin {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}
