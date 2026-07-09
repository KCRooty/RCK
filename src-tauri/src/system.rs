use std::sync::Mutex;

use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use sysinfo::{Networks, System};
use tauri_plugin_shell::ShellExt;

/// Información de solo lectura para el dashboard "Inicio" (inspirado en el
/// panel de Wintoys). No modifica nada, así que no pasa por el catálogo
/// firmado ni por la lista negra — es una consulta, no un tweak.
#[derive(Debug, Serialize, Deserialize)]
pub struct SystemInfo {
    pub computer_name: String,
    pub os_caption: String,
    pub os_build: String,
    pub cpu_name: String,
    pub gpu_name: String,
    pub ram_total_gb: f64,
}

const QUERY_SCRIPT: &str = r#"
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
[PSCustomObject]@{
    computer_name = $cs.Name
    os_caption    = $os.Caption
    os_build      = $os.BuildNumber
    cpu_name      = $cpu.Name
    gpu_name      = $gpu.Name
    ram_total_gb  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
} | ConvertTo-Json -Compress
"#;

pub async fn query(app: &tauri::AppHandle) -> Result<SystemInfo> {
    let output = app
        .shell()
        .command("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", QUERY_SCRIPT])
        .output()
        .await
        .context("no se pudo invocar powershell para leer la información del sistema")?;

    if !output.status.success() {
        bail!(
            "no se pudo leer la información del sistema: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(stdout.trim()).context("respuesta inesperada de PowerShell al leer la información del sistema")
}

/// Métricas en vivo para el dashboard "Inicio" (estilo Wintoys). A
/// diferencia de `SystemInfo` (estático, vía PowerShell), esto se consulta
/// varias veces por segundo desde el frontend, así que usa `sysinfo`
/// directamente en vez de lanzar un proceso `powershell.exe` por consulta.
#[derive(Debug, Serialize, Deserialize)]
pub struct LiveMetrics {
    pub cpu_percent: f32,
    pub ram_used_gb: f64,
    pub ram_total_gb: f64,
    pub ram_percent: f32,
    /// Bytes desde la última consulta, no un promedio calculado con
    /// timestamps — el contrato es que el frontend haga polling cada ~1s
    /// (ver `pollLiveMetrics` en app.astro), igual que un monitor de
    /// recursos normal, sin pretender precisión de laboratorio.
    pub network_down_bytes_per_sec: u64,
    pub network_up_bytes_per_sec: u64,
}

/// El cálculo de uso de CPU de `sysinfo` es un delta desde el refresco
/// anterior, así que necesita mantenerse vivo entre llamadas — no se puede
/// recrear `System`/`Networks` en cada consulta o el "delta" siempre sería
/// desde cero.
pub struct MetricsState(pub Mutex<(System, Networks)>);

impl Default for MetricsState {
    fn default() -> Self {
        // `Networks::new()` queda vacío hasta que se descubren las
        // interfaces; sin esto, `.refresh()` nunca ve ninguna y
        // down/up quedan siempre en 0.
        Self(Mutex::new((System::new(), Networks::new_with_refreshed_list())))
    }
}

pub fn read_live_metrics(state: &MetricsState) -> Result<LiveMetrics> {
    let mut guard = state.0.lock().map_err(|_| anyhow::anyhow!("no se pudo bloquear el estado de métricas"))?;
    let (sys, networks) = &mut *guard;

    sys.refresh_cpu_usage();
    sys.refresh_memory();
    networks.refresh();

    let (mut down, mut up) = (0u64, 0u64);
    for (_, data) in networks.iter() {
        down += data.received();
        up += data.transmitted();
    }

    let total = sys.total_memory();
    let used = sys.used_memory();

    Ok(LiveMetrics {
        cpu_percent: sys.global_cpu_usage(),
        ram_used_gb: bytes_to_gb(used),
        ram_total_gb: bytes_to_gb(total),
        ram_percent: if total > 0 { (used as f32 / total as f32) * 100.0 } else { 0.0 },
        network_down_bytes_per_sec: down,
        network_up_bytes_per_sec: up,
    })
}

fn bytes_to_gb(bytes: u64) -> f64 {
    (bytes as f64 / 1024.0 / 1024.0 / 1024.0 * 10.0).round() / 10.0
}
