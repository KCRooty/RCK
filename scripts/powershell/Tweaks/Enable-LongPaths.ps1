#Requires -Version 7.0

$script:FileSystemPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'

function Test-LongPathsEnabled {
    $value = Get-ItemProperty -Path $script:FileSystemPath -Name 'LongPathsEnabled' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.LongPathsEnabled -eq 1)
}

function Invoke-ApplyEnableLongPaths {
    Set-ItemProperty -Path $script:FileSystemPath -Name 'LongPathsEnabled' -Value 1 -Type DWord
}

function Invoke-RevertEnableLongPaths {
    Set-ItemProperty -Path $script:FileSystemPath -Name 'LongPathsEnabled' -Value 0 -Type DWord
}
