#Requires -Version 7.0

function Write-TweakLog {
    param([Parameter(Mandatory)][string]$Message)

    $logDir = Join-Path $env:LOCALAPPDATA 'RCK\logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $logFile = Join-Path $logDir "engine-$(Get-Date -Format 'yyyy-MM-dd').log"
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $logFile -Value "[$timestamp] $Message"
}

<#
Punto de entrada único para ejecutar un tweak. El Core en Rust ya resolvió
qué función invocar (Test-*/Invoke-Apply*/Invoke-Revert*) a partir del
catálogo firmado, y ya validó -targets contra la lista negra para Apply.
Este motor no vuelve a decidir "qué" tocar: solo ejecuta la función indicada
y deja constancia en el log.
#>
function Invoke-Tweak {
    param(
        [Parameter(Mandatory)][ValidateSet('Test', 'Apply', 'Revert')][string]$Action,
        [Parameter(Mandatory)][string]$FunctionName,
        [Parameter(Mandatory)][string]$TweakId
    )

    $command = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Función '$FunctionName' no encontrada para el tweak '$TweakId'. ¿Falta el archivo en scripts/powershell/Tweaks/?"
    }

    Write-TweakLog -Message "[$Action] '$TweakId' -> $FunctionName"

    $result = & $FunctionName

    if ($Action -eq 'Test') {
        # Normalizado a minúsculas para que Rust lo compare como string plano.
        Write-Output ([bool]$result).ToString().ToLowerInvariant()
        return
    }

    Write-TweakLog -Message "[$Action] '$TweakId' completado"
    Write-Output $result
}

# Dot-source de todos los tweaks al importar el módulo, para que sus
# funciones Test-*/Invoke-Apply*/Invoke-Revert* queden disponibles.
$tweaksDir = Join-Path $PSScriptRoot 'Tweaks'
if (Test-Path $tweaksDir) {
    Get-ChildItem -Path $tweaksDir -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

Export-ModuleMember -Function Invoke-Tweak, Write-TweakLog
