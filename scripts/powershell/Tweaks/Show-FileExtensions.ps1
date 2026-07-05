#Requires -Version 7.0

$script:ExplorerAdvancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

function Test-FileExtensionsShown {
    $value = Get-ItemProperty -Path $script:ExplorerAdvancedPath -Name 'HideFileExt' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.HideFileExt -eq 0)
}

function Invoke-ApplyShowFileExtensions {
    Set-ItemProperty -Path $script:ExplorerAdvancedPath -Name 'HideFileExt' -Value 0 -Type DWord
    Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
}

function Invoke-RevertShowFileExtensions {
    Set-ItemProperty -Path $script:ExplorerAdvancedPath -Name 'HideFileExt' -Value 1 -Type DWord
    Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
}
