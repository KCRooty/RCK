#Requires -Version 7.0

$script:PrefetchPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'

function Test-PrefetchSuperfetchDisabled {
    $service = Get-Service -Name 'SysMain' -ErrorAction SilentlyContinue
    return ($null -ne $service -and $service.StartType -eq 'Disabled')
}

function Invoke-ApplyDisablePrefetchSuperfetch {
    Set-Service -Name 'SysMain' -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name 'SysMain' -Force -ErrorAction SilentlyContinue
    if (Test-Path $script:PrefetchPath) {
        Set-ItemProperty -Path $script:PrefetchPath -Name 'EnablePrefetcher' -Value 0 -Type DWord
        Set-ItemProperty -Path $script:PrefetchPath -Name 'EnableSuperfetch' -Value 0 -Type DWord
    }
}

function Invoke-RevertDisablePrefetchSuperfetch {
    Set-Service -Name 'SysMain' -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name 'SysMain' -ErrorAction SilentlyContinue
    if (Test-Path $script:PrefetchPath) {
        Set-ItemProperty -Path $script:PrefetchPath -Name 'EnablePrefetcher' -Value 3 -Type DWord
        Set-ItemProperty -Path $script:PrefetchPath -Name 'EnableSuperfetch' -Value 3 -Type DWord
    }
}
