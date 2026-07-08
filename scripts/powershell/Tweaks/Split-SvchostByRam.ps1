#Requires -Version 7.0

$script:ControlPath = 'HKLM:\SYSTEM\CurrentControlSet\Control'
$script:DefaultThresholdKB = 3670016

function Get-TargetThresholdKB {
    $totalMemoryKB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1KB
    [Math]::Round($totalMemoryKB)
}

function Test-SvchostSplitByRam {
    $value = Get-ItemProperty -Path $script:ControlPath -Name 'SvcHostSplitThresholdInKB' -ErrorAction SilentlyContinue
    if (-not $value) {
        return $false
    }
    return ($value.SvcHostSplitThresholdInKB -ge $script:DefaultThresholdKB)
}

function Invoke-ApplySplitSvchostByRam {
    $threshold = Get-TargetThresholdKB
    Set-ItemProperty -Path $script:ControlPath -Name 'SvcHostSplitThresholdInKB' -Value $threshold -Type DWord
}

function Invoke-RevertSplitSvchostByRam {
    Remove-ItemProperty -Path $script:ControlPath -Name 'SvcHostSplitThresholdInKB' -ErrorAction SilentlyContinue
}
