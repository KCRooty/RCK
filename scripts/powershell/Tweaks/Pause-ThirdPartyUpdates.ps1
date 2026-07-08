#Requires -Version 7.0

$script:ThirdPartyUpdateTaskPatterns = @('GoogleUpdateTask*', 'Adobe Acrobat Update Task', 'AdobeAAMUpdater*')

function Get-ThirdPartyUpdateTasks {
    $tasks = @()
    foreach ($pattern in $script:ThirdPartyUpdateTaskPatterns) {
        $tasks += Get-ScheduledTask -TaskName $pattern -ErrorAction SilentlyContinue
    }
    return $tasks
}

function Test-ThirdPartyUpdatesPaused {
    $tasks = Get-ThirdPartyUpdateTasks
    if (-not $tasks) {
        return $true
    }
    return -not ($tasks | Where-Object { $_.State -eq 'Ready' })
}

function Invoke-ApplyPauseThirdPartyUpdates {
    Get-ThirdPartyUpdateTasks | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
}

function Invoke-RevertPauseThirdPartyUpdates {
    Get-ThirdPartyUpdateTasks | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
}
