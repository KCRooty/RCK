#Requires -Version 7.0

$script:ClsidPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'

function Test-ClassicContextMenuEnabled {
    if (-not (Test-Path $script:ClsidPath)) {
        return $false
    }
    $value = (Get-Item -Path $script:ClsidPath).GetValue('')
    return ($value -eq '')
}

function Invoke-ApplyClassicContextMenu {
    New-Item -Path $script:ClsidPath -Force | Out-Null
    Set-ItemProperty -Path $script:ClsidPath -Name '(Default)' -Value ''
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

function Invoke-RevertClassicContextMenu {
    Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}
