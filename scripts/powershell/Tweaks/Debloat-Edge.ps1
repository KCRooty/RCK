#Requires -Version 7.0

$script:EdgePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$script:EdgePolicyValues = @{
    HideFirstRunExperience              = 1
    HubsSidebarEnabled                  = 0
    PersonalizationReportingEnabled     = 0
    ShowRecommendationsEnabled          = 0
    UserFeedbackAllowed                 = 0
    ConfigureDoNotTrack                 = 1
    EdgeCollectionsEnabled              = 0
    DiagnosticData                      = 0
}

function Test-EdgeDebloated {
    if (-not (Test-Path $script:EdgePolicyPath)) {
        return $false
    }
    $value = Get-ItemProperty -Path $script:EdgePolicyPath -Name 'HideFirstRunExperience' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.HideFirstRunExperience -eq 1)
}

function Invoke-ApplyDebloatEdge {
    New-Item -Path $script:EdgePolicyPath -Force | Out-Null
    foreach ($name in $script:EdgePolicyValues.Keys) {
        Set-ItemProperty -Path $script:EdgePolicyPath -Name $name -Value $script:EdgePolicyValues[$name] -Type DWord
    }
}

function Invoke-RevertDebloatEdge {
    if (Test-Path $script:EdgePolicyPath) {
        foreach ($name in $script:EdgePolicyValues.Keys) {
            Remove-ItemProperty -Path $script:EdgePolicyPath -Name $name -ErrorAction SilentlyContinue
        }
    }
}
