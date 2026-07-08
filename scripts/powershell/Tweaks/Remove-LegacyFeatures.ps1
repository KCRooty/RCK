#Requires -Version 7.0

$script:LegacyFeatureNames = @('Internet-Explorer-Optional-amd64', 'FaxServicesClientPackage')

function Test-LegacyFeaturesRemoved {
    foreach ($name in $script:LegacyFeatureNames) {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction SilentlyContinue
        if ($feature -and $feature.State -eq 'Enabled') {
            return $false
        }
    }
    return $true
}

function Invoke-ApplyRemoveLegacyFeatures {
    foreach ($name in $script:LegacyFeatureNames) {
        Disable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction SilentlyContinue | Out-Null
    }
}

function Invoke-RevertRemoveLegacyFeatures {
    foreach ($name in $script:LegacyFeatureNames) {
        Enable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction SilentlyContinue | Out-Null
    }
}
