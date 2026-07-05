#Requires -Version 7.0

function Invoke-RunRebuildSearchIndex {
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue

    $dbPath = Join-Path $env:ProgramData 'Microsoft\Search\Data\Applications\Windows'
    if (Test-Path $dbPath) {
        Get-ChildItem -Path $dbPath -Filter '*.edb' -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }

    Start-Service -Name WSearch -ErrorAction SilentlyContinue
}
