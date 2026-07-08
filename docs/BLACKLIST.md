# Lista negra dura

Componentes que el motor de RCK **nunca** permite tocar, ni en modo `expert`. Esto no es configurable desde la UI ni desde el catálogo. Se aplica en dos capas independientes en el Core de Rust, antes de invocar cualquier script:

1. **`blacklist.rs`** — valida los `targets.services`/`targets.registry` que cada tweak declara en su YAML, antes de invocar `Invoke-Tweak -Action Apply`.
2. **`guard.rs`** — escanea el *contenido real* de todos los `.ps1` bajo `scripts/powershell/` al arrancar la app, y rechaza el arranque si alguno usa un comando o toca una ruta prohibidos. Esto cubre el caso en que un tweak declare `targets` inocentes pero su script haga algo distinto — la capa 1 confía en lo que el YAML *dice* que toca, la capa 2 no confía en nada y lee el script tal cual se va a ejecutar.

Un tweak cuyo `id`, `targets` o script intente modificar cualquiera de los siguientes se rechaza, incluso si viene de un catálogo firmado correctamente.

## Origen de esta lista: análisis de Platinum Optimizer

La incorporación de `guard.rs` (2026-07-09) viene de leer el `.bat` real de **Platinum Optimizer 7.4** (el "tierra quemada" que motivó todo el diseño reversible de RCK) y el config real de **Optimizer** (hellzerg) y **Chris Titus WinUtil**, disponibles en este equipo. Confirmó tres técnicas concretas que RCK debe bloquear a nivel de comando, no solo de servicio:

- **`takeown`/`icacls` sobre DLLs de Windows Update** (`WaaSMedicSvc.dll`, `wuaueng.dll`): se apropia del archivo, lo renombra a `*_BAK.dll` y así el servicio de Update queda roto de forma que ni `sc config ... start= auto` lo arregla — hay que restaurar el archivo a mano. `guard.rs` prohíbe `takeown` e `icacls` en cualquier script, sin excepción.
- **`bcdedit /set` sobre banderas de seguridad de arranque**: `hypervisorlaunchtype off`, `vsmlaunchtype Off`, `isolatedcontext No` (desactivan Hyper-V/VBS) y `nx OptIn` (baja la protección DEP de `AlwaysOn` a solo-programas-marcados). Ningún tweak de "rendimiento" justifica bajar la seguridad del arranque. `guard.rs` prohíbe `bcdedit` por completo — RCK no edita el BCD.
- **Borrado recursivo forzado de carpetas de drivers/sistema**: `rmdir /s /q "...\NVIDIA Corporation\NvTelemetry"`, borrado bajo `DriverStore\FileRepository`. `guard.rs` prohíbe combinar un verbo de borrado (`Remove-Item`, `del`, `rd`, `rmdir`) con rutas que contengan `system32`, `syswow64`, `driverstore`, `windows.old`, `windowsapps` o la carpeta de historial de Defender — sin prohibir el borrado en sí, así que herramientas legítimas como `Clear-TempFiles.ps1` (que sí borra recursivamente `$env:TEMP`) siguen funcionando.

También confirmó que `net user ... /delete` se usa para borrar `defaultuser0` sin preguntar — prohibido igual, RCK nunca gestiona cuentas de usuario.

## Servicios que nunca se deshabilitan

- `WinDefend` (Windows Defender Antivirus Service) — solo se permite *configurar* exclusiones, no deshabilitar el servicio.
- `wuauserv` (Windows Update) — se permite pausar/diferir, no deshabilitar el servicio de forma permanente.
- `WaaSMedicSvc`, `UsoSvc`, `uhssvc` — soporte de Windows Update; es justo lo que Platinum Optimizer ataca con `takeown` (ver arriba).
- `SecurityHealthService`, `WdNisSvc`, `Sense`, `wscsvc` — Defender/ATP y Security Center; deshabilitarlos apaga las notificaciones de seguridad aunque el AV siga "activo" en apariencia.
- `EventLog`, `RpcSs`, `DcomLaunch`, `Winmgmt` (WMI) — dependencias críticas del propio sistema y de RCK.
- `bfe` (Base Filtering Engine), `mpssvc` (Windows Firewall) — deshabilitarlos rompe el firewall silenciosamente.
- `TrustedInstaller` (servicing stack) — necesario para actualizaciones y reparación de componentes.

## Componentes/rutas de registro protegidas

- `HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\*`
- `HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\*` (parámetros de red core, distinto de tweaks de red "seguros" como deshabilitar Nagle, que sí están permitidos como tweak explícito)
- `HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\*` — la vía "por policy" para apagar Defender sin tocar el servicio directamente; igual de bloqueada.
- Claves de arranque (`BCD`) — no se editan nunca por script (ver `guard.rs` arriba). No hay excepciones, ni siquiera cosméticas como `bootux disabled`.

## Comandos prohibidos a nivel de script (`guard.rs`)

- `takeown`, `icacls` — apropiación/cambio de ACL de archivos del sistema.
- `bcdedit` — cualquier edición del BCD.
- `diskpart`, `format c:` — particionado/formateo.
- `vssadmin delete` — borrado de shadow copies (mata la capacidad de restaurar).
- `net user` — gestión de cuentas de Windows.
- `cipher /w` — borrado seguro de espacio libre (irreversible por diseño, no tiene cabida en un tweak).
- Borrado (`Remove-Item`/`del`/`rd`/`rmdir`) combinado con `system32`, `syswow64`, `driverstore`, `windows.old`, `windowsapps` en la misma línea.

## Acciones prohibidas explícitamente

- Eliminar o corromper el Store de componentes (`WinSxS`).
- Deshabilitar UAC por completo (se permite bajar el nivel del slider, no ponerlo a 0 sin advertencia explícita y doble confirmación).
- Borrar App Installer / winget si RCK depende de él para algún flujo futuro.
- Cualquier tweak que impida la creación de restore points (`vssadmin`/`SystemRestore` deshabilitado).

## Proceso para modificar esta lista

Cambios a esta lista requieren:
1. Revisión manual — no se puede vaciar la lista para "desbloquear" un tweak.
2. Documentar por qué el riesgo es aceptable y qué mitigación existe (backup, confirmación, etc.).

Esta lista es intencionalmente conservadora. El objetivo de RCK es debloat + privacidad + rendimiento, no convertirse en una herramienta que deje el sistema inestable o irreparable.
