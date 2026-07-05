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

✅ Fase 1, 2 y 2b: motor PowerShell + catálogo firmado (10 tweaks: debloat/privacidad/rendimiento/sistema) + catálogo de apps (13 apps vía winget/choco) + catálogo de herramientas (5 acciones puntuales: DNS, temporales, papelera, caché de iconos, índice de búsqueda) + UI dual-mode (web/desktop) con dashboard "Inicio" y panel "Ver Script", con estética inspirada en WinScript/Wintoys — todo funcionando de punta a punta.

🚧 Pendiente (Fase 3): perfiles compartibles, presets, modo dry-run en la UI, empaquetado real con iconos propios, navegador de apps instaladas (tipo Wintoys), medidores de sistema en vivo, ampliar catálogo. Ver `docs/ARCHITECTURE.md` para el roadmap completo.

## Aviso

RCK modifica configuración del sistema operativo (registro, servicios, políticas). Úsalo bajo tu propio riesgo. Cada tweak indica su nivel de riesgo y RCK crea un punto de restauración antes de aplicar cambios, pero ninguna herramienta sustituye tener tus propios backups.
