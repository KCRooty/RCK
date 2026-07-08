#Requires -Version 7.0

$script:KeyboardPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters'
$script:MousePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters'
$script:IncreasedSize = 30
$script:DefaultSize = 100

function Test-InputQueueSizeIncreased {
    $kbd = Get-ItemProperty -Path $script:KeyboardPath -Name 'KeyboardDataQueueSize' -ErrorAction SilentlyContinue
    $mouse = Get-ItemProperty -Path $script:MousePath -Name 'MouseDataQueueSize' -ErrorAction SilentlyContinue
    return ($null -ne $kbd -and $kbd.KeyboardDataQueueSize -eq $script:IncreasedSize -and
            $null -ne $mouse -and $mouse.MouseDataQueueSize -eq $script:IncreasedSize)
}

function Invoke-ApplyIncreaseInputQueueSize {
    Set-ItemProperty -Path $script:KeyboardPath -Name 'KeyboardDataQueueSize' -Value $script:IncreasedSize -Type DWord
    Set-ItemProperty -Path $script:MousePath -Name 'MouseDataQueueSize' -Value $script:IncreasedSize -Type DWord
}

function Invoke-RevertIncreaseInputQueueSize {
    Set-ItemProperty -Path $script:KeyboardPath -Name 'KeyboardDataQueueSize' -Value $script:DefaultSize -Type DWord
    Set-ItemProperty -Path $script:MousePath -Name 'MouseDataQueueSize' -Value $script:DefaultSize -Type DWord
}
