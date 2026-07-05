use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
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
