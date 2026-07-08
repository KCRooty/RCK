#Requires -Version 7.0

$script:ExplorerPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'

function Test-BingSearchDisabled {
    $value = Get-ItemProperty -Path $script:ExplorerPolicyPath -Name 'DisableSearchBoxSuggestions' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DisableSearchBoxSuggestions -eq 1)
}

function Invoke-ApplyDisableBingSearch {
    New-Item -Path $script:ExplorerPolicyPath -Force | Out-Null
    Set-ItemProperty -Path $script:ExplorerPolicyPath -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord
}

function Invoke-RevertDisableBingSearch {
    if (Test-Path $script:ExplorerPolicyPath) {
        Remove-ItemProperty -Path $script:ExplorerPolicyPath -Name 'DisableSearchBoxSuggestions' -ErrorAction SilentlyContinue
    }
}
