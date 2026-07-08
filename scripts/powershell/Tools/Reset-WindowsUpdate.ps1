#Requires -Version 7.0

# Método oficial de Microsoft (KB971058) para restablecer Windows Update:
# parar los servicios que tienen los archivos de caché abiertos, renombrar
# (no borrar) las carpetas de caché para que Windows las regenere vacías, y
# volver a arrancar los servicios. No hace falta tocar la propiedad ni los
# permisos de ningún archivo: al estar los servicios parados, el propio
# proceso ya tiene permiso de sobra para renombrar sus carpetas de caché.
$script:UpdateServices = @('wuauserv', 'bits', 'cryptsvc', 'msiserver')

function Invoke-RunResetWindowsUpdate {
    foreach ($service in $script:UpdateServices) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }

    $softwareDistribution = Join-Path $env:SystemRoot 'SoftwareDistribution'
    $catroot2 = Join-Path $env:SystemRoot 'System32\catroot2'

    foreach ($path in @($softwareDistribution, $catroot2)) {
        if (Test-Path $path) {
            $backupPath = "$path.bak"
            if (Test-Path $backupPath) {
                Remove-Item -Path $backupPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            Rename-Item -Path $path -NewName (Split-Path -Leaf $backupPath) -ErrorAction SilentlyContinue
        }
    }

    foreach ($service in $script:UpdateServices) {
        Start-Service -Name $service -ErrorAction SilentlyContinue
    }
}
