use std::sync::Mutex;

use tauri::{AppHandle, Manager, State};
use tauri_plugin_shell::ShellExt;

use crate::blacklist;
use crate::catalog::{self, Catalog, Tweak};

pub struct CatalogState(pub Mutex<Catalog>);

fn resource_path(app: &AppHandle, relative: &str) -> Result<std::path::PathBuf, String> {
    app.path()
        .resolve(relative, tauri::path::BaseDirectory::Resource)
        .map_err(|e| format!("no se pudo resolver la ruta de recursos '{relative}': {e}"))
}

#[tauri::command]
pub fn list_tweaks(state: State<CatalogState>, category: Option<String>) -> Result<Vec<Tweak>, String> {
    let catalog = state.0.lock().map_err(|e| e.to_string())?;
    let tweaks = match category {
        Some(cat) => catalog.by_category(&cat).into_iter().cloned().collect(),
        None => catalog.tweaks.clone(),
    };
    Ok(tweaks)
}

#[tauri::command]
pub async fn get_tweak_status(app: AppHandle, state: State<'_, CatalogState>, id: String) -> Result<bool, String> {
    run_engine_action(&app, &state, &id, "Test").await.map(|out| out.trim() == "true")
}

#[tauri::command]
pub async fn apply_tweak(app: AppHandle, state: State<'_, CatalogState>, id: String) -> Result<(), String> {
    run_engine_action(&app, &state, &id, "Apply").await.map(|_| ())
}

#[tauri::command]
pub async fn revert_tweak(app: AppHandle, state: State<'_, CatalogState>, id: String) -> Result<(), String> {
    run_engine_action(&app, &state, &id, "Revert").await.map(|_| ())
}

#[tauri::command]
pub async fn create_restore_point_cmd(app: AppHandle, description: String) -> Result<(), String> {
    crate::backup::create_restore_point(&app, &description)
        .await
        .map_err(|e| e.to_string())
}

/// El Core en Rust resuelve qué función PowerShell corresponde a la acción
/// pedida (Test/Apply/Revert) a partir del catálogo ya verificado, y —solo
/// para Apply— valida los `targets` declarados contra la lista negra antes
/// de invocar nada. `Engine.psm1::Invoke-Tweak` solo ejecuta la función por
/// nombre; no decide qué tocar.
async fn run_engine_action(
    app: &AppHandle,
    state: &State<'_, CatalogState>,
    id: &str,
    action: &str,
) -> Result<String, String> {
    let function_name = {
        let catalog = state.0.lock().map_err(|e| e.to_string())?;
        let tweak = catalog
            .find(id)
            .ok_or_else(|| format!("tweak desconocido: {id}"))?;

        if action == "Apply" {
            reject_if_blacklisted(tweak)?;
        }

        match action {
            "Test" => tweak.test.clone(),
            "Apply" => tweak.apply.clone(),
            "Revert" => tweak.revert.clone(),
            other => return Err(format!("acción desconocida: {other}")),
        }
    };

    let engine_path = resource_path(app, "scripts/powershell/Engine.psm1")?;

    let command = format!(
        "Import-Module '{}'; Invoke-Tweak -Action '{}' -FunctionName '{}' -TweakId '{}'",
        engine_path.display(),
        action,
        function_name,
        id
    );

    let output = app
        .shell()
        .command("powershell")
        .args(["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", &command])
        .output()
        .await
        .map_err(|e| format!("no se pudo invocar powershell: {e}"))?;

    if !output.status.success() {
        return Err(format!(
            "Invoke-Tweak ({action}) falló para '{id}': {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn reject_if_blacklisted(tweak: &Tweak) -> Result<(), String> {
    for service in &tweak.targets.services {
        if blacklist::is_service_blacklisted(service) {
            return Err(format!(
                "'{}' intenta modificar el servicio protegido '{service}' — rechazado por la lista negra",
                tweak.id
            ));
        }
    }
    for registry_path in &tweak.targets.registry {
        if blacklist::is_registry_path_blacklisted(registry_path) {
            return Err(format!(
                "'{}' intenta modificar la ruta de registro protegida '{registry_path}' — rechazado por la lista negra",
                tweak.id
            ));
        }
    }
    Ok(())
}

pub fn load_initial_catalog(app: &AppHandle) -> anyhow::Result<Catalog> {
    let catalog_dir = resource_path(app, "catalog").map_err(anyhow::Error::msg)?;
    catalog::load_catalog(&catalog_dir)
}
