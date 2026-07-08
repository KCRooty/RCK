#Requires -Version 7.0

function Test-Smb1Disabled {
    $config = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
    return ($null -ne $config -and $config.EnableSMB1Protocol -eq $false)
}

function Invoke-ApplyDisableSmb1 {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
    Disable-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -NoRestart -ErrorAction SilentlyContinue | Out-Null
}

function Invoke-RevertDisableSmb1 {
    Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force -ErrorAction SilentlyContinue
    Enable-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -NoRestart -ErrorAction SilentlyContinue | Out-Null
}
