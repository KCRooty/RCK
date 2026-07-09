use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use tauri_plugin_shell::ShellExt;

/// Un programa realmente instalado en el sistema, leído de las claves de
/// registro `...\Uninstall\*` — el mismo lugar del que lee "Aplicaciones y
/// características" de Windows. Distinto del catálogo de apps (`apps.rs`):
/// aquello es un catálogo curado de qué se puede *instalar* vía winget/choco;
/// esto es un espejo de lo que ya *está* instalado, con la opción de
/// desinstalarlo — el equivalente a la lista de apps de Wintoys.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstalledApp {
    pub name: String,
    pub version: Option<String>,
    pub publisher: Option<String>,
    pub size_mb: Option<f64>,
    pub install_date: Option<String>,
    /// Comando de desinstalación tal cual lo registró el instalador.
    /// Se pasa por `guard::check_content` antes de ejecutarse.
    pub uninstall_command: Option<String>,
}

// No usamos `Get-CimInstance Win32_Product`: es lento y reconfigura/repara
// cada paquete MSI que enumera (efecto secundario documentado, no un rumor).
// Leer directamente las claves de Uninstall es lo mismo que hace el propio
// panel de Windows, sin ese coste.
const LIST_SCRIPT: &str = r#"
$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
    Select-Object `
        @{n='name'; e={$_.DisplayName}}, `
        @{n='version'; e={$_.DisplayVersion}}, `
        @{n='publisher'; e={$_.Publisher}}, `
        @{n='size_mb'; e={ if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1024, 1) } else { $null } }}, `
        @{n='install_date'; e={$_.InstallDate}}, `
        @{n='uninstall_command'; e={ if ($_.QuietUninstallString) { $_.QuietUninstallString } else { $_.UninstallString } }} |
    Sort-Object name |
    ConvertTo-Json -Compress
"#;

pub async fn list_installed_apps(app: &tauri::AppHandle) -> Result<Vec<InstalledApp>> {
    let output = app
        .shell()
        .command("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", LIST_SCRIPT])
        .output()
        .await
        .context("no se pudo invocar powershell para listar las apps instaladas")?;

    if !output.status.success() {
        bail!(
            "no se pudo listar las apps instaladas: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let trimmed = stdout.trim();
    if trimmed.is_empty() {
        return Ok(Vec::new());
    }

    // Un solo resultado deserializa como objeto suelto, no como array de un
    // elemento — ConvertTo-Json de PowerShell hace eso siempre.
    if trimmed.starts_with('{') {
        let single: InstalledApp =
            serde_json::from_str(trimmed).context("respuesta inesperada de PowerShell al listar apps instaladas")?;
        return Ok(vec![single]);
    }

    serde_json::from_str(trimmed).context("respuesta inesperada de PowerShell al listar apps instaladas")
}

/// Ejecuta el comando de desinstalación tal cual lo registró el instalador
/// original (ej. `MsiExec.exe /X{GUID} /qn` o la ruta a un `uninstall.exe`
/// propio). Es, por naturaleza, ejecución de un comando arbitrario que RCK
/// no controla — la única red de seguridad es `guard::check_content`, la
/// misma que protege el catálogo firmado y el editor de scripts.
pub async fn uninstall(app: &tauri::AppHandle, uninstall_command: &str) -> Result<String> {
    crate::guard::check_content(uninstall_command)?;

    let output = app
        .shell()
        .command("cmd")
        .args(["/c", uninstall_command])
        .output()
        .await
        .context("no se pudo invocar el desinstalador")?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    if !output.status.success() {
        bail!(
            "el desinstalador terminó con error: {}\n{}",
            String::from_utf8_lossy(&output.stderr),
            stdout
        );
    }

    Ok(stdout)
}
