use std::path::PathBuf;

use anyhow::{bail, Context, Result};
use chrono::Local;
use tauri_plugin_shell::ShellExt;

/// Crea un punto de restauración de Windows antes de aplicar una tanda de tweaks.
pub async fn create_restore_point(app: &tauri::AppHandle, description: &str) -> Result<()> {
    let script = format!(
        "Checkpoint-Computer -Description '{}' -RestorePointType 'MODIFY_SETTINGS'",
        description.replace('\'', "''")
    );

    let output = app
        .shell()
        .command("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .await
        .context("no se pudo invocar powershell para crear el restore point")?;

    if !output.status.success() {
        bail!(
            "Checkpoint-Computer falló: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }
    Ok(())
}

/// Exporta una clave de registro a un `.reg` en el directorio de backups antes
/// de que un tweak la modifique, para poder revertir manualmente si algo falla.
pub async fn export_registry_key(app: &tauri::AppHandle, key_path: &str) -> Result<PathBuf> {
    let backup_dir = backups_dir()?;
    std::fs::create_dir_all(&backup_dir)?;

    let timestamp = Local::now().format("%Y%m%d-%H%M%S");
    let safe_name = key_path.replace(['\\', ':'], "_");
    let dest = backup_dir.join(format!("{timestamp}_{safe_name}.reg"));

    let output = app
        .shell()
        .command("reg")
        .args(["export", key_path, &dest.to_string_lossy(), "/y"])
        .output()
        .await
        .context("no se pudo invocar 'reg export'")?;

    if !output.status.success() {
        bail!(
            "'reg export' falló para {key_path}: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    Ok(dest)
}

fn backups_dir() -> Result<PathBuf> {
    let local_appdata = std::env::var("LOCALAPPDATA").context("LOCALAPPDATA no está definido")?;
    Ok(PathBuf::from(local_appdata).join("RCK").join("backups"))
}
