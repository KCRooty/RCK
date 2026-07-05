# Arquitectura de RCK

## Principio rector

Todo cambio debe ser **reversible y verificable**. Ningún tweak se aplica sin:
1. saber exactamente qué hace (declarado en el catálogo, no oculto en código disperso),
2. tener forma de deshacerlo (`revert` obligatorio),
3. respetar la lista negra dura de componentes esenciales (ver `BLACKLIST.md`).

Esto es lo que diferencia a RCK de optimizadores "tierra quemada" como Platinum.

## Capas

```
┌─────────────────────────────────────────────┐
│  UI (Astro + TypeScript)                     │
│  Categorías: Debloat · Privacidad ·          │
│  Rendimiento · Servicios · Apariencia        │
└───────────────┬───────────────────────────────┘
                │ Tauri IPC (invoke/emit)
┌───────────────▼───────────────────────────────┐
│  Core (Rust, src-tauri/)                       │
│  - Verificación de firma Ed25519 del catálogo  │
│  - Gestión de restore point / backup registro  │
│  - Enforcement de la lista negra               │
│  - Invocación de scripts vía tauri-plugin-shell│
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Catálogo de Tweaks (catalog/tweaks/*.yaml)    │
│  id · categoría · riesgo · apply · revert      │
│  firmado con clave privada (nunca en el repo)  │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Motor de ejecución (PowerShell 7)              │
│  scripts/powershell/Engine.psm1                │
│  Test-TweakStatus / Invoke-Apply / Invoke-Revert│
└─────────────────────────────────────────────────┘
```

### 1. UI — Astro + TypeScript

Empaquetada por Tauri como app de escritorio nativa (no Electron: binario más pequeño, sin runtime Chromium embebido propio, usa el WebView del sistema).

Esquema de categorías inspirado en WinToys: `Debloat`, `Privacidad`, `Rendimiento`, `Servicios`, `Red`, `Apariencia`, `Actualizaciones`. Cada tweak se muestra con badge de riesgo (verde/ámbar/rojo) y checkbox. Incluye buscador y presets (`Balanced`, `Privacy`, `Gaming`, `Extreme`).

### 2. Core — Rust (`src-tauri/`)

Capa fina de orquestación, no de lógica de negocio:
- `catalog.rs`: carga y parsea el catálogo YAML.
- `signature.rs`: verifica la firma Ed25519 del catálogo contra la clave pública embebida en el binario. Si la firma no es válida, el catálogo se rechaza (mismo modelo que OptimizerNXT).
- `backup.rs`: crea restore point de Windows (`Checkpoint-Computer`) y exporta a `.reg` las claves de registro que un tweak va a tocar, antes de aplicarlo.
- `commands.rs`: comandos IPC expuestos a la UI (`list_tweaks`, `get_tweak_status`, `apply_tweak`, `revert_tweak`, `create_restore_point`, `export_profile`, `import_profile`).

### 3. Catálogo de tweaks — YAML declarativo y firmado

Cada tweak es una entrada de datos, no un módulo de código disperso:

```yaml
id: privacy.disable-telemetry
category: privacy
risk: safe          # safe | moderate | advanced | expert
requires_restart: false
description: Deshabilita la telemetría de Windows (nivel de diagnóstico a "Security").
apply: Invoke-ApplyDisableTelemetry
revert: Invoke-RevertDisableTelemetry
test: Test-DisableTelemetryStatus
```

El catálogo completo se firma con `scripts/sign-catalog.mjs` usando una clave privada Ed25519 que **nunca se commitea**. El Core en Rust verifica esa firma en tiempo de arranque contra la clave pública (`catalog/public_key.pem`, esa sí versionada). Esto asegura que un catálogo modificado por un tercero (o corrupto) no se ejecute silenciosamente.

### 4. Motor de ejecución — PowerShell 7

Cada tweak referenciado en el catálogo tiene 3 funciones correspondientes en `scripts/powershell/Tweaks/`:
- `Test-*`: ¿está aplicado?
- `Invoke-Apply*`: aplica el cambio.
- `Invoke-Revert*`: lo deshace.

El motor (`Engine.psm1`) nunca ejecuta un tweak directamente: siempre pasa por `Invoke-Tweak`, que (1) consulta la lista negra, (2) crea el backup puntual si el tweak toca registro, (3) ejecuta, (4) registra en el log.

### 5. Seguridad

- Restore point automático antes de aplicar cualquier tanda de cambios.
- Backup granular: export `.reg` de las claves afectadas antes de tocarlas.
- Lista negra dura (`BLACKLIST.md`): componentes que el motor nunca permite tocar, ni en modo Expert.
- Modo dry-run: muestra qué haría un tweak sin ejecutarlo.
- Firma criptográfica del catálogo (Ed25519).

### 6. Gestor de perfiles (backup/restore de configuración)

Snapshot del estado (qué tweaks están aplicados) exportable/importable como `.json` — permite compartir perfiles ("Gaming", "Privacidad máxima").

### 7. Logging

Cada acción se registra con timestamp en `%LOCALAPPDATA%\RCK\logs\`, para poder auditar "qué cambió esto" después.

## Por qué esta pila

- **Tauri 2 en vez de Electron o WPF puro**: binario pequeño, WebView nativo del sistema, actualizador automático incluido, y permite reusar Astro/TS del lado del frontend.
- **PowerShell como motor de ejecución, no Rust puro**: acceso nativo total a WMI/registro/servicios sin wrappers, y mantiene la lógica de cada tweak auditable línea por línea por cualquiera (transparencia = confianza, justo lo que falta en Platinum).
- **Catálogo declarativo y firmado en vez de lógica dispersa**: permite "unificar" referencias como WinToys/Optimizer/Winaero Tweaker como entradas de datos, no como integraciones de código distintas, y añade una capa de integridad que ninguna de esas referencias resuelve tan bien salvo OptimizerNXT.

## Roadmap

- **Fase 1** (actual): motor PowerShell + catálogo + primer tweak de ejemplo, sin UI.
- **Fase 2**: UI Astro completa + empaquetado Tauri + verificación de firma en runtime.
- **Fase 3**: perfiles compartibles + presets + modo dry-run pulido + actualizador automático del catálogo.
