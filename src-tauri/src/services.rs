use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use tauri_plugin_shell::ShellExt;

/// Snapshot de un servicio de Windows en un momento dado. Distinto del
/// catálogo de tweaks: esto no es curado ni firmado, es una lectura en vivo
/// de `Get-Service` — el equivalente al panel "Servicios" de Wintoys.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceInfo {
    pub name: String,
    pub display_name: String,
    pub status: String,
    pub start_type: String,
}

const LIST_SCRIPT: &str = r#"
@(Get-Service | Sort-Object DisplayName | Select-Object Name, DisplayName, Status, StartType) |
    ConvertTo-Json -Compress -Depth 3
"#;

pub async fn list_services(app: &tauri::AppHandle) -> Result<Vec<ServiceInfo>> {
    let output = app
        .shell()
        .command("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", LIST_SCRIPT])
        .output()
        .await
        .context("no se pudo invocar powershell para listar servicios")?;

    if !output.status.success() {
        bail!("no se pudo listar los servicios: {}", String::from_utf8_lossy(&output.stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);

    #[derive(Deserialize)]
    struct RawService {
        #[serde(rename = "Name")]
        name: String,
        #[serde(rename = "DisplayName")]
        display_name: String,
        #[serde(rename = "Status")]
        status: String,
        #[serde(rename = "StartType")]
        start_type: String,
    }

    let raw: Vec<RawService> = serde_json::from_str(stdout.trim())
        .context("respuesta inesperada de PowerShell al listar servicios")?;

    Ok(raw
        .into_iter()
        .map(|s| ServiceInfo {
            name: s.name,
            display_name: s.display_name,
            status: s.status,
            start_type: s.start_type,
        })
        .collect())
}

/// Cambia el tipo de inicio de un servicio. Deliberadamente no ofrece
/// start/stop en caliente — solo el tipo de arranque, que es lo que Wintoys
/// expone en su lista y lo único que tiene sentido "revertir" desde una UI
/// (parar un servicio crítico a mitad de sesión por error no tiene vuelta
/// atrás inmediata; cambiar cómo arranca la próxima vez sí).
///
/// La validación contra la lista negra vive en `commands.rs` (mismo patrón
/// que `reject_if_blacklisted` para tweaks), no aquí — este módulo solo sabe
/// hablar con `Set-Service`.
pub async fn set_service_startup(app: &tauri::AppHandle, name: &str, start_type: &str) -> Result<()> {
    if !["Automatic", "Manual", "Disabled"].contains(&start_type) {
        bail!("tipo de inicio inválido: '{start_type}' (debe ser Automatic, Manual o Disabled)");
    }

    let script = format!("Set-Service -Name '{name}' -StartupType {start_type}");
    let output = app
        .shell()
        .command("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .await
        .context("no se pudo invocar powershell para cambiar el servicio")?;

    if !output.status.success() {
        bail!(
            "no se pudo cambiar '{name}' a {start_type}: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    Ok(())
}
