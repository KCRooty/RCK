#Requires -Version 7.0

function Test-OneDriveRemoved {
    return (-not (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe")) -and
           (-not (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue))
}

function Invoke-ApplyRemoveOneDrive {
    Stop-Process -Name 'OneDrive' -Force -ErrorAction SilentlyContinue

    $uninstaller = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $uninstaller)) {
        $uninstaller = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    }
    if (Test-Path $uninstaller) {
        Start-Process -FilePath $uninstaller -ArgumentList '/uninstall' -Wait -NoNewWindow
    }

    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -ErrorAction SilentlyContinue
}

function Invoke-RevertRemoveOneDrive {
    $setup = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $setup)) {
        $setup = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    }
    if (Test-Path $setup) {
        Start-Process -FilePath $setup -Wait -NoNewWindow
    }
}
