# Lista negra dura

Componentes que el motor de RCK **nunca** permite tocar, ni en modo `expert`. Esto no es configurable desde la UI ni desde el catálogo — está reforzado en `Engine.psm1` (`Test-Blacklist`) y validado de nuevo en el Core de Rust antes de invocar cualquier script.

Un tweak cuyo `id` o cuyo scriptblock intente modificar cualquiera de los siguientes se rechaza en tiempo de ejecución, incluso si viene de un catálogo firmado correctamente.

## Servicios que nunca se deshabilitan

- `WinDefend` (Windows Defender Antivirus Service) — solo se permite *configurar* exclusiones, no deshabilitar el servicio.
- `wuauserv` (Windows Update) — se permite pausar/diferir, no deshabilitar el servicio de forma permanente.
- `EventLog`, `RpcSs`, `DcomLaunch`, `Winmgmt` (WMI) — dependencias críticas del propio sistema y de RCK.
- `bfe` (Base Filtering Engine), `mpssvc` (Windows Firewall) — deshabilitarlos rompe el firewall silenciosamente.
- `TrustedInstaller` (servicing stack) — necesario para actualizaciones y reparación de componentes.

## Componentes/rutas de registro protegidas

- `HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\*`
- `HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\*` (parámetros de red core, distinto de tweaks de red "seguros" como deshabilitar Nagle, que sí están permitidos como tweak explícito)
- Claves de arranque (`BCD`) — no se editan por script, solo se exponen acciones ya soportadas oficialmente (ej. `bcdedit /set bootux disabled`).

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
