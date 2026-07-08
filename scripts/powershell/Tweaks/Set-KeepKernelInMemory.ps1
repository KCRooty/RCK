#Requires -Version 7.0

$script:MemManagementPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'

function Test-KernelKeptInMemory {
    $value = Get-ItemProperty -Path $script:MemManagementPath -Name 'DisablePagingExecutive' -ErrorAction SilentlyContinue
    return ($null -ne $value -and $value.DisablePagingExecutive -eq 1)
}

function Invoke-ApplyKeepKernelInMemory {
    Set-ItemProperty -Path $script:MemManagementPath -Name 'DisablePagingExecutive' -Value 1 -Type DWord
}

function Invoke-RevertKeepKernelInMemory {
    Set-ItemProperty -Path $script:MemManagementPath -Name 'DisablePagingExecutive' -Value 0 -Type DWord
}
