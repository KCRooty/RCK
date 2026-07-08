#Requires -Version 7.0

$script:StickyKeysPath = 'HKCU:\Control Panel\Accessibility\StickyKeys'
$script:DisabledFlags = '506'
$script:DefaultFlags = '510'

function Test-StickyKeysDisabled {
    $value = Get-ItemProperty -Path $script:StickyKeysPath -Name 'Flags' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.Flags -eq $script:DisabledFlags)
}

function Invoke-ApplyDisableStickyKeys {
    Set-ItemProperty -Path $script:StickyKeysPath -Name 'Flags' -Value $script:DisabledFlags -Type String
}

function Invoke-RevertDisableStickyKeys {
    Set-ItemProperty -Path $script:StickyKeysPath -Name 'Flags' -Value $script:DefaultFlags -Type String
}
