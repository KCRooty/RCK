# Arquitectura de RCK

## Principio rector

Todo cambio debe ser **reversible y verificable**. Ningún tweak se aplica sin:
1. saber exactamente qué hace (declarado en el catálogo, no oculto en código disperso),
2. tener forma de deshacerlo (`revert` obligatorio),
3. respetar la lista negra dura de componentes esenciales (ver `BLACKLIST.md`).

Esto es lo que diferencia a RCK de optimizadores "tierra quemada" como Platinum.

## Web y desktop desde el mismo código

Inspirado directamente en WinScript: **el mismo frontend Astro se despliega como web pública y se empaqueta como app de escritorio**. La diferencia está solo en qué pasa al pulsar "aplicar":

- **Modo desktop** (dentro de Tauri): la UI llama a `invoke()` y el Core en Rust aplica el cambio en vivo, con estado en tiempo real y reversión con un clic.
- **Modo web** (navegador normal, sin Tauri): el navegador no puede tocar el registro ni servicios, así que en vez de aplicar nada, el frontend concatena el código fuente de los tweaks elegidos en un único `.ps1` y lo ofrece para descargar. El usuario lo corre él mismo, como administrador.

`src/lib/runtime.ts` detecta el modo (`"__TAURI_INTERNALS__" in window`). `src/lib/scriptBuilder.ts` construye el script para el modo web; `src/lib/tauriClient.ts` envuelve los comandos IPC para el modo desktop. La página `src/pages/app.astro` es el único punto de entrada que necesita ramificar por modo — el resto del código (catálogo, tipos) es compartido.

`src/pages/index.astro` es la landing pública (marketing), separada del constructor (`app.astro`).

## Capas

```
┌─────────────────────────────────────────────┐
│  UI (Astro + TypeScript) — app.astro          │
│  Categorías: Debloat · Privacidad ·          │
│  Rendimiento · Servicios · Red · Apariencia  │
│  · Actualizaciones · Sistema · Apps          │
└───────────────┬───────────────┬───────────────┘
      modo desktop│               │modo web
    Tauri IPC (invoke)      scriptBuilder.ts
                │               │
┌───────────────▼───────────────┐   ┌──────────────┐
│  Core (Rust, src-tauri/)       │   │ .ps1 generado │
│  - Verificación de firma       │   │ para descargar│
│    Ed25519 del catálogo        │   └──────────────┘
│  - Restore point / backup reg. │
│  - Enforcement de lista negra  │
│  - Invocación vía plugin-shell │
└───────────────┬─────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Catálogo (catalog/tweaks/*.yaml,              │
│  catalog/apps/*.yaml) — firmado como una unidad│
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Motor de ejecución (PowerShell 7)              │
│  scripts/powershell/Engine.psm1                │
│  Tweaks: Test-* / Invoke-Apply* / Invoke-Revert*│
│  Apps: Invoke-InstallApp / Invoke-UninstallApp  │
└─────────────────────────────────────────────────┘
```

### 1. UI — Astro + TypeScript

Empaquetada por Tauri como app de escritorio nativa (no Electron: binario más pequeño, sin runtime Chromium embebido propio, usa el WebView del sistema). El mismo build también se despliega como sitio estático para el modo web.

Categorías de tweaks: `Debloat`, `Privacidad`, `Rendimiento`, `Servicios`, `Red`, `Apariencia`, `Actualizaciones`, `Sistema` — más una sección `Apps` (navegadores, herramientas de desarrollo, utilidades, multimedia, comunicación) para instalación masiva vía winget/Chocolatey. Cada tweak se muestra con badge de riesgo (verde/ámbar/rojo) y checkbox de selección.

### 2. Core — Rust (`src-tauri/`)

Capa fina de orquestación, no de lógica de negocio:
- `catalog.rs`: carga y parsea el catálogo de tweaks (YAML).
- `apps.rs`: carga el catálogo de apps (YAML, sin scriptblocks propios).
- `signature.rs`: verifica la firma Ed25519 sobre **todo** `catalog/` (tweaks + apps) contra la clave pública embebida. Si la firma no es válida, el catálogo se rechaza (mismo modelo que OptimizerNXT).
- `blacklist.rs`: lista negra dura de servicios/rutas de registro protegidas.
- `backup.rs`: crea restore point de Windows (`Checkpoint-Computer`) y exporta a `.reg` las claves de registro que un tweak va a tocar.
- `commands.rs`: comandos IPC — tweaks (`list_tweaks`, `get_tweak_status`, `apply_tweak`, `revert_tweak`, `create_restore_point_cmd`) y apps (`list_apps`, `get_app_status`, `install_app`, `uninstall_app`). Antes de aplicar un tweak, valida sus `targets` contra la lista negra — el Core decide qué es seguro ejecutar, `Engine.psm1` solo ejecuta.

### 3. Catálogo — YAML declarativo y firmado

Cada tweak es una entrada de datos, no un módulo de código disperso:

```yaml
id: privacy.disable-telemetry
category: privacy
risk: safe          # safe | moderate | advanced | expert
requires_restart: false
description: Deshabilita la telemetría de Windows (nivel de diagnóstico a "Security").
targets:
  services: [DiagTrack]
  registry: [HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
script: Disable-Telemetry.ps1   # archivo en scripts/powershell/Tweaks/
apply: Invoke-ApplyDisableTelemetry
revert: Invoke-RevertDisableTelemetry
test: Test-DisableTelemetryStatus
```

Las apps (`catalog/apps/*.yaml`) son más simples: no llevan scriptblocks, solo `winget`/`choco` — la instalación usa las funciones genéricas del motor.

El catálogo completo (tweaks + apps) se firma con `scripts/sign-catalog.mjs` usando una clave privada Ed25519 que **nunca se commitea**. El Core en Rust verifica esa firma en tiempo de arranque contra la clave pública (`catalog/public_key.pem`, esa sí versionada). En el modo web no se re-verifica esa firma en el navegador: la confianza ahí viene de que `src/data/catalog.generated.json` se genera y despliega junto con el propio sitio (misma cadena de confianza que el hosting), no de un catálogo de terceros. La firma protege específicamente al modo desktop de catálogos corruptos o de terceros.

### 4. Motor de ejecución — PowerShell 7

Cada tweak referenciado en el catálogo tiene 3 funciones correspondientes en `scripts/powershell/Tweaks/`:
- `Test-*`: ¿está aplicado?
- `Invoke-Apply*`: aplica el cambio.
- `Invoke-Revert*`: lo deshace.

El motor (`Engine.psm1`) nunca decide qué tocar: siempre pasa por `Invoke-Tweak`, que recibe ya resuelto el nombre de función desde el Core (que ya validó la lista negra), ejecuta, y registra en el log. Para apps, expone `Invoke-InstallApp`/`Invoke-UninstallApp`/`Test-AppInstalled`, genéricas (reciben gestor de paquetes + id, no hay un script por app).

### 5. Generador de catálogo web (`scripts/build-web-catalog.mjs`)

Antes de cada `dev`/`build` (hooks `predev`/`prebuild` en `package.json`), recorre `catalog/tweaks/**/*.yaml` + `catalog/apps/**/*.yaml`, incluye el código fuente `.ps1` de cada tweak, y escribe `src/data/catalog.generated.json`. Esto es lo único que el frontend necesita: nunca lee YAML directamente ni en desktop ni en web (en desktop, el Core en Rust hace su propio parseo del catálogo real para el IPC; el JSON generado solo alimenta el listado/UI y el modo de exportación de script).

### 6. Seguridad

- Restore point automático antes de aplicar cualquier tanda de cambios (desktop) o al inicio del script generado (web).
- Backup granular: export `.reg` de las claves afectadas antes de tocarlas (desktop).
- Lista negra dura (`BLACKLIST.md`): componentes que el motor nunca permite tocar, ni en modo Expert.
- Firma criptográfica del catálogo completo (Ed25519), verificada al arrancar el desktop.

### 7. Logging

Cada acción se registra con timestamp en `%LOCALAPPDATA%\RCK\logs\` (modo desktop). El script generado para modo web imprime su propio progreso por consola.

## Por qué esta pila

- **Tauri 2 en vez de Electron o WPF puro**: binario pequeño, WebView nativo del sistema, y permite reusar el mismo Astro/TS tanto para el desktop como para la web pública — igual que WinScript.
- **PowerShell como motor de ejecución, no Rust puro**: acceso nativo total a WMI/registro/servicios sin wrappers, y mantiene la lógica de cada tweak auditable línea por línea por cualquiera (transparencia = confianza, justo lo que falta en Platinum). Además es el mismo código que corre embebido en el script exportado para el modo web.
- **Catálogo declarativo y firmado en vez de lógica dispersa**: permite "unificar" referencias como WinToys/Optimizer/Winaero Tweaker como entradas de datos, y añade una capa de integridad que ninguna de esas referencias resuelve tan bien salvo OptimizerNXT.
- **Apps como catálogo separado, sin scriptblocks propios**: instalar software es un problema ya resuelto por winget/Chocolatey; no tiene sentido tratarlo como un tweak con apply/revert custom.

## Roadmap

- **Fase 1** (completa): motor PowerShell + catálogo firmado + primer tweak de ejemplo.
- **Fase 2** (completa): UI Astro dual-mode (web + desktop) + catálogo de apps + ~10 tweaks reales en debloat/privacidad/rendimiento/sistema.
- **Fase 3**: perfiles compartibles (exportar/importar selección como `.json`), presets (`Balanced`/`Privacy`/`Gaming`/`Extreme`), modo dry-run en la UI, empaquetado real (`tauri build`) con iconos, y ampliar el catálogo (más tweaks de servicios/red/apariencia, más apps).
