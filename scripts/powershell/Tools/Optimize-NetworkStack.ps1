#Requires -Version 7.0

function Invoke-RunOptimizeNetworkStack {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null

    $qosPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched'
    New-Item -Path $qosPath -Force | Out-Null
    Set-ItemProperty -Path $qosPath -Name 'NonBestEffortLimit' -Value 0 -Type DWord

    Clear-DnsClientCache
    netsh winsock reset catalog | Out-Null
}
