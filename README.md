# RCK

**RCK** es un optimizador y configurador todo-en-uno para **Windows 10/11**: debloat, privacidad, rendimiento, servicios y utilidades varias, en una sola app ligera.

A diferencia de herramientas "tierra quemada" (Platinum, ISOs debloateadas), RCK está diseñado para que **todo cambio sea reversible y verificable**: nunca toca componentes esenciales del sistema, siempre permite deshacer, y siempre puedes ver qué hace un tweak antes de aplicarlo.

Inspirado en (pero no acoplado a) WinScript, OptimizerNXT, WinToys, Chris Titus WinUtil, SDI y Winaero Tweaker — unificados bajo un único catálogo de tweaks firmado criptográficamente.

## Stack

- **UI**: Astro + TypeScript, empaquetado como app de escritorio con **Tauri 2** (Rust)
- **Catálogo de tweaks**: YAML declarativo, **firmado con Ed25519** (ver `catalog/README.md`)
- **Motor de ejecución**: PowerShell 7 (`scripts/powershell/`), invocado desde Rust vía `tauri-plugin-shell`
- **Seguridad**: restore point automático, backup granular de registro, lista negra dura de componentes intocables, modo dry-run

Ver la arquitectura completa en [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Estructura del repo

```
src/            UI Astro (frontend)
src-tauri/      Backend Rust (Tauri): IPC, verificación de firma, backups
catalog/        Catálogo de tweaks (YAML) + clave pública + firma
scripts/        Motor PowerShell (Test/Apply/Revert por tweak) + script de firmado
docs/           Arquitectura, lista negra, decisiones de diseño
```

## Requisitos de desarrollo

- Node.js 20+
- Rust stable + `cargo`
- Windows 10/11 para probar los tweaks (el frontend/UI puede desarrollarse en cualquier SO)

## Quick start

```bash
npm install
npm run tauri:dev
```

## Estado

🚧 Fase 1 en progreso: motor de tweaks + catálogo + primer tweak de ejemplo. Ver `docs/ARCHITECTURE.md` para el roadmap completo.

## Aviso

RCK modifica configuración del sistema operativo (registro, servicios, políticas). Úsalo bajo tu propio riesgo. Cada tweak indica su nivel de riesgo y RCK crea un punto de restauración antes de aplicar cambios, pero ninguna herramienta sustituye tener tus propios backups.
