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

Antes de cada `dev`/`build` (hooks `predev`/`prebuild` en `package.json`), recorre `catalog/tweaks/**/*.yaml` + `catalog/apps/**/*.yaml` + `catalog/tools/**/*.yaml`, incluye el código fuente `.ps1` de cada tweak/herramienta, y escribe `src/data/catalog.generated.json`. Esto es lo único que el frontend necesita: nunca lee YAML directamente ni en desktop ni en web (en desktop, el Core en Rust hace su propio parseo del catálogo real para el IPC; el JSON generado solo alimenta el listado/UI y el modo de exportación de script).

### 5b. Herramientas — acciones puntuales sin estado

A diferencia de un tweak (que tiene test/apply/revert porque representa un estado persistente), una herramienta es una acción de un solo disparo: vaciar la papelera, limpiar temporales, reconstruir la caché de iconos, etc. `catalog/tools/*.yaml` solo declara `run` (una función `Invoke-Run*`), sin `test` ni `revert`. Se seleccionan y aplican con el mismo flujo unificado que tweaks/apps (misma barra de acción, mismo script exportado), pero no tienen switch de estado — no hay "aplicado/no aplicado" que consultar.

### 5c. Dashboard "Inicio"

Panel inicial (inspirado en la pantalla de inicio de Wintoys) con dos partes:
- Info del equipo (nombre, Windows, CPU, GPU, RAM), leída una vez al cargar vía `get_system_info` (Rust invoca `Get-CimInstance` sobre `Win32_ComputerSystem`/`Win32_OperatingSystem`/`Win32_Processor`/`Win32_VideoController`). Solo disponible en modo desktop — en web se muestra un aviso, ya que el navegador no tiene acceso al hardware.
- Resumen del catálogo (tweaks/apps/herramientas disponibles), siempre visible en ambos modos porque viene del JSON generado, no de una consulta al sistema.

### 5d. "Ver Script" — vista previa en vivo

Panel que muestra el `.ps1` combinado de la selección actual (tweaks + apps + herramientas), recalculado en cada cambio de selección — inspirado directamente en la pestaña "View Script" de WinScript. Disponible en ambos modos: en desktop es informativo (así verías exactamente qué se ejecutaría si aplicas), en web es la fuente del botón de descarga.

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

## Estética e inspiración de UI

El aspecto visual (switches tipo iOS, sidebar con iconos por categoría, acento violeta, tarjetas de riesgo) está tomado deliberadamente de las referencias que motivaron este proyecto: los switches y el layout de sidebar de **WinScript**, el dashboard de tarjetas de **Wintoys**, y el panel "Ver Script" de WinScript. La sidebar en árbol de **Winaero Tweaker** y las secciones con toggles en dos columnas de **Optimizer** quedan como referencia para una futura vista más densa (ver Fase 3), pero no se replicaron 1:1 en esta pasada.

## Roadmap

- **Fase 1** (completa): motor PowerShell + catálogo firmado + primer tweak de ejemplo.
- **Fase 2** (completa): UI Astro dual-mode (web + desktop) + catálogo de apps + ~10 tweaks reales en debloat/privacidad/rendimiento/sistema.
- **Fase 2b** (completa): rediseño visual inspirado en WinScript/Wintoys, subsistema de Herramientas (acciones puntuales), dashboard "Inicio" con info del sistema, panel "Ver Script" con vista previa en vivo.
- **Fase 3** (en progreso):
  - ✅ Presets (`catalog/presets.yaml`: Balanced/Privacidad máxima/Gaming/Extreme) — atajos de selección, no ejecutables por sí mismos, fuera del alcance de la firma criptográfica porque solo referencian ids ya firmados.
  - ✅ Perfiles compartibles: exportar/importar la selección actual como `.json` (botones en "Ver Script").
  - ✅ Estado en vivo de tweaks/apps en modo desktop: cada categoría/panel de apps consulta `get_tweak_status`/`get_app_status` de forma perezosa (una vez por panel, con botón de refresco manual) y muestra "Aplicado"/"Instalada" junto a cada item. El panel "Ver Script" ya cumplía el rol de modo dry-run, así que no se construyó como feature aparte.
  - ✅ Catálogo ampliado: 36 tweaks (de 10), 75 apps (de 13, incluye categorías nuevas gaming/security/networking/productivity), 6 herramientas (de 5). Varios tweaks nuevos están inspirados directamente en scripts reales del propio Rooty (`Nexo_Net_Optimizer.bat`, `FullScreenFix.bat`, `Optimizar PC V5.8`): cola de entrada de teclado/ratón, kernel en RAM, prioridad de CPU para juegos, DNS Cloudflare, optimización de pila de red como herramienta puntual.
  - ✅ Compatibilidad con perfiles de WinScript: `src/lib/winscriptCompat.ts` mapea las claves planas `{ "clave": true/false }` que exporta WinScript a ids de tweaks/apps de RCK (import) y a la inversa (export). No es 1:1 — varias claves de WinScript convergen en un único tweak de RCK más amplio, y las claves que tocarían componentes de la lista negra (`limitdefender`, `coreisolation`, `ipv6`, `updatepause`) se reportan como protegidas en vez de ignorarse en silencio. Botones dedicados en el panel "Ver Script".
  - ✅ Empaquetado real (`tauri build`): genera `RCK_0.1.0_x64-setup.exe` (NSIS) y `RCK_0.1.0_x64_en-US.msi`. Se corrigió `tauri.conf.json` para bundlear solo `catalog/{tweaks,apps,tools}`, `public_key.pem` y `catalog.sig` — el glob inicial (`../catalog/**/*`) empaquetaba por error `private_key.pem` dentro del instalador. Verificado de nuevo el 2026-07-09: `rck.exe` arranca sin errores (firma verificada, catálogo cargado, escaneo de `guard.rs` en verde) y los dos instaladores se generan correctamente.
  - ✅ Catálogo ampliado de nuevo (2026-07-09): 49 tweaks (de 36), 90 apps (de 75), 10 herramientas (de 6). Nuevos tweaks: fullscreen optimizations, network throttling, split de svchost por RAM, sticky keys, Windows Ink, Teredo, SMB1, error reporting, buscador de la barra de tareas, snap flyout, long paths, Bing search, memory integrity (Core Isolation/HVCI, `risk: advanced` con advertencia explícita de seguridad). Nuevas apps: Godot, Audacity, Equalizer APO, K-Lite, FFmpeg, yt-dlp, Spicetify, DaVinci Resolve, Git Extensions, WinMerge, Temurin JDK, .NET Desktop Runtime, NanaZip, Mem Reduct, CrystalDiskMark. Nuevas herramientas: SFC scan, DISM RestoreHealth, reset de Windows Update (método oficial KB971058, sin `takeown`), informe de batería.
  - ✅ **Hardening de seguridad tras analizar herramientas reales** (2026-07-09): se leyó el `.bat` completo de **Platinum Optimizer 7.4** (el "tierra quemada" que motivó el diseño de RCK, disponible en `F:\Software\` de este equipo) más los configs reales de **Optimizer** (hellzerg) y **Chris Titus WinUtil** encontrados en disco. Confirmó técnicas concretas (`takeown`/`icacls` sobre DLLs de Windows Update, `bcdedit` bajando DEP/VBS, borrado recursivo de `DriverStore`) que llevaron a:
    - Ampliar `blacklist.rs` con `WaaSMedicSvc`/`UsoSvc`/`uhssvc`/`SecurityHealthService`/`WdNisSvc`/`Sense`/`wscsvc` y la ruta de registro `HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`.
    - Añadir **`src-tauri/src/guard.rs`**, una segunda capa de defensa que escanea el contenido real de cada `.ps1` al arrancar (no lo que el YAML *dice* que toca) y rechaza `takeown`, `icacls`, `bcdedit`, `diskpart`, `net user`, `format c:`, `cipher /w`, y cualquier borrado combinado con `system32`/`syswow64`/`driverstore`/`windows.old`/`windowsapps`. Ver `docs/BLACKLIST.md` para el detalle completo y el razonamiento caso por caso.
  - ✅ Ampliado `winscriptCompat.ts` con las claves reales que faltaban (`stickykeys`, `snapflyout`, y las apps `Spicetify`/`Audacity`/`EqualizerAPO`/`FFmpeg`/`yt-dlp`/`GitExtensions`/`KLite`/`Godot`/`WinMerge`/`NET8`) tras confirmar contra los perfiles reales `SCRIPT.json` y `Script Optimizar PC By Rooty (Core).json` de este equipo.
  - ✅ Verificado con Playwright contra el `dist/` real (servido por HTTP, no `file://` — el protocolo `file://` bloquea por CORS la carga de módulos ES de Astro/Vite, así que no sirve para probar el build de producción): navegación entre las 13 categorías, los 49 tweaks/90 apps/10 herramientas nuevos están presentes, los toggles actualizan el script en vivo, y el preset "Extreme" genera un script de ~31 KB sin errores de consola.
  - ✅ **Gestor de Servicios en vivo** (2026-07-09, tras revisar capturas reales de Wintoys): nuevo panel "Servicios" que lee `Get-Service` en tiempo real (`src-tauri/src/services.rs`, comando `list_services`) y permite cambiar el tipo de inicio (Automático/Manual/Deshabilitado) de cualquier servicio no protegido (`set_service_startup`, mismo `blacklist::is_service_blacklisted` que ya protegía los tweaks — no hay una lista separada que pueda desincronizarse). Deliberadamente sin start/stop en caliente: parar un servicio crítico a mitad de sesión no tiene vuelta atrás inmediata, cambiar cómo arranca la próxima vez sí. No pasa por el catálogo firmado (es lectura/escritura directa del estado del sistema, no un tweak curado), pero sí por la misma lista negra.
  - ✅ **Script ejecutable y editable** ("que la gente lo customice a su gusto... y se pueda ejecutar desde la app", inspirado en el "Run Script" de WinScript): el `<pre>` de solo lectura en "Ver Script" pasó a ser un `<textarea>` editable. Un nuevo botón "▶ Ejecutar en este PC" corre exactamente ese texto vía el comando `run_raw_script`, que lo escribe a un `.ps1` temporal y lo invoca con `-File` (no `-Command`, para evitar problemas de escapado con scripts largos). Esta es la única vía de RCK que **no** pasa por la lista negra basada en `targets` ni por la firma del catálogo — es, a propósito, la vía de escape para power users. La única red de seguridad que sí aplica: `guard::check_content` (la misma función que ya escaneaba `catalog/tweaks/`/`catalog/tools/` al arrancar, ahora extraída y reutilizada) rechaza el mismo puñado de patrones catastróficos (`takeown`/`icacls`/`bcdedit`, borrados bajo `system32`...) antes de ejecutar cualquier cosa. Un botón "↻ Regenerar desde selección" y un flag `scriptEdited` evitan que el auto-refresco pise ediciones manuales.
  - ✅ Catálogo ampliado de nuevo (2026-07-09): 53 tweaks (de 49) — `privacy.disable-background-apps`, `privacy.disable-lockscreen-camera`, `updates.disable-delivery-optimization`, `performance.disable-wake-timers` — gaps confirmados contra capturas reales de Wintoys/WinScript/UniGetUI que no estaban cubiertos todavía.
  - ✅ Pase de diseño hacia algo más minimalista: menos badges apilados por tarjeta (el pill de estado en vivo ahora empieza oculto en vez de mostrar "—" permanente; "requiere reinicio" pasó de badge a un hint de texto discreto), tipografía de tarjeta separada en título/meta/descripción en vez de todo dentro de un `<strong>`, bordes con menos contraste.
  - ✅ **Medidores en vivo de CPU/RAM/red** (2026-07-09, primera sesión corriendo de verdad en Windows vía teleport): nuevo comando `get_live_metrics` en `src-tauri/src/system.rs`, usando el crate `sysinfo` en vez de invocar `powershell.exe` — a diferencia de todo lo demás en RCK, esto se consulta una vez por segundo mientras el panel "Inicio" está visible, y lanzar un proceso nuevo por consulta sería demasiado caro. `System`/`Networks` viven en estado gestionado por Tauri (`MetricsState`) para que el cálculo de uso de CPU y las deltas de red sean respecto al refresco anterior, no absolutos. Bug real encontrado y corregido durante la verificación: `Networks::new()` queda vacío hasta que se descubre la lista de interfaces, así que sin `new_with_refreshed_list()` la lectura de red se habría quedado en 0 para siempre (confirmado con un log temporal: `interfaces=0` antes del fix, valores reales tras corregirlo).
  - ✅ **Navegador de apps instaladas con desinstalación** (`src-tauri/src/installed_apps.rs`, comandos `list_installed_apps`/`uninstall_installed_app`): lee las claves de registro `...\CurrentVersion\Uninstall\*` (HKLM 64/32-bit + HKCU), el mismo lugar del que lee "Aplicaciones y características" — deliberadamente no usa `Get-CimInstance Win32_Product`, que además de lento reconfigura/repara cada paquete MSI que enumera. Desinstalar ejecuta el `QuietUninstallString`/`UninstallString` original del propio instalador, pasado primero por `guard::check_content` (mismo escudo que protege el catálogo firmado y el editor de scripts) porque es, por naturaleza, ejecución de un comando que RCK no controla. Verificado contra datos reales de este equipo: 102 apps encontradas, nombres/versión/editor/tamaño correctos.
  - 🚧 Pendiente: icono propio (los actuales son placeholders), y seguir ampliando cobertura de mapeo WinScript (queda un resto de claves de terceros — telemetría de Adobe/NVIDIA/VSCode, Windows Update pause, etc. — sin tweak equivalente todavía). Deliberadamente fuera de alcance: scripts de activación de Windows/Office (MAS) — WinScript los incluye, RCK no.
