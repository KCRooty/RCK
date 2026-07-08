#Requires -Version 7.0

function Test-TeredoDisabled {
    $state = (netsh interface teredo show state) -join "`n"
    return ($state -match 'Type\s*:\s*disabled')
}

function Invoke-ApplyDisableTeredo {
    netsh interface teredo set state disabled | Out-Null
}

function Invoke-RevertDisableTeredo {
    netsh interface teredo set state default | Out-Null
}
