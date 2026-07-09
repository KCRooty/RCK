# RCK

**RCK** es un optimizador y configurador todo-en-uno para **Windows 10/11**: debloat, privacidad, rendimiento, servicios y utilidades varias, en una sola app ligera.

A diferencia de herramientas "tierra quemada" (Platinum, ISOs debloateadas), RCK está diseñado para que **todo cambio sea reversible y verificable**: nunca toca componentes esenciales del sistema, siempre permite deshacer, y siempre puedes ver qué hace un tweak antes de aplicarlo.

Inspirado en (pero no acoplado a) WinScript, OptimizerNXT, WinToys, Chris Titus WinUtil, SDI y Winaero Tweaker — unificados bajo un único catálogo de tweaks firmado criptográficamente.

Como WinScript, **el mismo código sirve como web pública y como app de escritorio**: en el navegador, eliges tweaks/apps y descargas un `.ps1` para correrlo tú mismo; en la app de escritorio (Tauri), se aplican en vivo con estado en tiempo real y reversión con un clic.

## Stack

- **UI**: Astro + TypeScript — `src/pages/index.astro` (landing) y `src/pages/app.astro` (constructor, dual-mode)
- **Desktop**: **Tauri 2** (Rust) envuelve la misma UI y aplica cambios en vivo por IPC
- **Catálogo**: YAML declarativo (tweaks + apps), **firmado con Ed25519** (ver `catalog/README.md`)
- **Motor de ejecución**: PowerShell 7 (`scripts/powershell/`), invocado desde Rust vía `tauri-plugin-shell` en desktop, o embebido en el `.ps1` descargado en modo web
- **Seguridad**: restore point automático, backup granular de registro, lista negra dura de componentes intocables

Ver la arquitectura completa en [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Estructura del repo

```
src/            UI Astro (landing + constructor dual-mode) + lib compartida (catálogo, script builder, cliente Tauri)
src-tauri/      Backend Rust (Tauri): IPC, verificación de firma, backups, apps
catalog/        Catálogo de tweaks y apps (YAML) + clave pública + firma
scripts/        Motor PowerShell (Test/Apply/Revert por tweak) + firmado + generador de catálogo web
docs/           Arquitectura, lista negra, decisiones de diseño
```

## Requisitos de desarrollo

- Node.js 20+
- Rust stable + `cargo`
- Windows 10/11 para probar los tweaks (el frontend/UI puede desarrollarse en cualquier SO)

## Quick start

```bash
npm install

# Genera tu propio par de claves y firma el catálogo (una vez)
node scripts/sign-catalog.mjs --generate-keys
npm run sign-catalog

# Modo web (navegador, genera scripts .ps1 descargables)
npm run dev

# Modo desktop (Tauri, aplica en vivo — requiere Windows + Rust)
npm run tauri:dev
```

## Estado

✅ Fase 1, 2 y 2b: motor PowerShell + catálogo firmado + UI dual-mode (web/desktop) con dashboard "Inicio", presets, perfiles compartibles y panel "Ver Script", con estética inspirada en WinScript/Wintoys — todo funcionando de punta a punta.

✅ Fase 3 (catálogo + hardening): **53 tweaks** (debloat/privacidad/rendimiento/sistema/red/apariencia/servicios/updates), **90 apps** (winget/choco, 9 subcategorías) y **10 herramientas** puntuales. Lista negra dura de servicios/registro (`src-tauri/src/blacklist.rs`) ampliada tras analizar herramientas "tierra quemada" reales (Platinum Optimizer, Optimizer, WinUtil) encontradas en disco, más una segunda capa de defensa (`src-tauri/src/guard.rs`) que escanea el contenido de cada script al arrancar y rechaza comandos como `takeown`/`icacls`/`bcdedit` sin importar lo que declare el YAML. Ver `docs/BLACKLIST.md` para el detalle completo. Empaquetado real verificado: `npm run tauri:build` genera `rck.exe` + instaladores NSIS/MSI funcionales.

✅ Fase 3b: gestor de **Servicios** en vivo (lectura real de `Get-Service`, cambio de tipo de inicio, protegido por la misma lista negra), y editor de **script ejecutable** en "Ver Script" — puedes editar libremente el `.ps1` generado y correrlo tal cual desde la app (`guard::check_content` lo escanea contra los mismos patrones catastróficos prohibidos antes de ejecutar, aunque no pase por la lista negra basada en `targets`). Pase de diseño hacia algo más minimalista (menos badges apilados, tipografía más contenida).

🚧 Pendiente: navegador de apps instaladas con desinstalación (tipo Wintoys, distinto del catálogo curado de instalación — y del nuevo gestor de Servicios), medidores de CPU/RAM/red en vivo en el dashboard, iconos propios (los actuales son placeholder). Deliberadamente fuera de alcance: scripts de activación (MAS) — no es algo que este proyecto vaya a incluir. Ver `docs/ARCHITECTURE.md` para el roadmap completo.

## Aviso

RCK modifica configuración del sistema operativo (registro, servicios, políticas). Úsalo bajo tu propio riesgo. Cada tweak indica su nivel de riesgo y RCK crea un punto de restauración antes de aplicar cambios, pero ninguna herramienta sustituye tener tus propios backups.
