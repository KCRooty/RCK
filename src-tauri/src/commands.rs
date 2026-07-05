use std::sync::Mutex;

use tauri::{AppHandle, Manager, State};
use tauri_plugin_shell::ShellExt;

use crate::apps::{self, AppCatalog, AppEntry};
use crate::blacklist;
use crate::catalog::{self, Catalog, Tweak};

pub struct CatalogState(pub Mutex<Catalog>);
pub struct AppCatalogState(pub Mutex<AppCatalog>);

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
    let (function_name, registry_targets) = {
        let catalog = state.0.lock().map_err(|e| e.to_string())?;
        let tweak = catalog
            .find(id)
            .ok_or_else(|| format!("tweak desconocido: {id}"))?;

        if action == "Apply" {
            reject_if_blacklisted(tweak)?;
        }

        let function_name = match action {
            "Test" => tweak.test.clone(),
            "Apply" => tweak.apply.clone(),
            "Revert" => tweak.revert.clone(),
            other => return Err(format!("acción desconocida: {other}")),
        };
        (function_name, tweak.targets.registry.clone())
    };

    // Backup granular: antes de tocar el registro, se exporta cada clave
    // afectada a un .reg — independiente del restore point general.
    if action == "Apply" {
        for registry_path in &registry_targets {
            crate::backup::export_registry_key(app, registry_path)
                .await
                .map_err(|e| format!("no se pudo respaldar '{registry_path}' antes de aplicar '{id}': {e}"))?;
        }
    }

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

pub fn load_initial_apps(app: &AppHandle) -> anyhow::Result<AppCatalog> {
    let catalog_dir = resource_path(app, "catalog").map_err(anyhow::Error::msg)?;
    apps::load_apps(&catalog_dir)
}

#[tauri::command]
pub fn list_apps(state: State<AppCatalogState>, subcategory: Option<String>) -> Result<Vec<AppEntry>, String> {
    let catalog = state.0.lock().map_err(|e| e.to_string())?;
    let apps = match subcategory {
        Some(sub) => catalog.by_subcategory(&sub).into_iter().cloned().collect(),
        None => catalog.apps.clone(),
    };
    Ok(apps)
}

#[tauri::command]
pub async fn get_app_status(
    app: AppHandle,
    state: State<'_, AppCatalogState>,
    id: String,
    manager: String,
) -> Result<bool, String> {
    let package_id = resolve_package_id(&state, &id, &manager)?;
    let out = run_app_action(&app, "Test-AppInstalled", &manager, &package_id).await?;
    Ok(out.trim().eq_ignore_ascii_case("true"))
}

#[tauri::command]
pub async fn install_app(
    app: AppHandle,
    state: State<'_, AppCatalogState>,
    id: String,
    manager: String,
) -> Result<(), String> {
    let package_id = resolve_package_id(&state, &id, &manager)?;
    run_app_action(&app, "Invoke-InstallApp", &manager, &package_id).await.map(|_| ())
}

#[tauri::command]
pub async fn uninstall_app(
    app: AppHandle,
    state: State<'_, AppCatalogState>,
    id: String,
    manager: String,
) -> Result<(), String> {
    let package_id = resolve_package_id(&state, &id, &manager)?;
    run_app_action(&app, "Invoke-UninstallApp", &manager, &package_id).await.map(|_| ())
}

fn resolve_package_id(state: &State<AppCatalogState>, id: &str, manager: &str) -> Result<String, String> {
    let catalog = state.0.lock().map_err(|e| e.to_string())?;
    let entry = catalog.find(id).ok_or_else(|| format!("app desconocida: {id}"))?;
    match manager {
        "winget" => entry.winget.clone(),
        "choco" => entry.choco.clone(),
        other => return Err(format!("gestor de paquetes desconocido: {other}")),
    }
    .ok_or_else(|| format!("'{id}' no tiene un identificador de {manager}"))
}

async fn run_app_action(
    app: &AppHandle,
    function_name: &str,
    manager: &str,
    package_id: &str,
) -> Result<String, String> {
    let engine_path = resource_path(app, "scripts/powershell/Engine.psm1")?;

    let command = format!(
        "Import-Module '{}'; {} -Manager '{}' -PackageId '{}'",
        engine_path.display(),
        function_name,
        manager,
        package_id
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
            "{function_name} falló para '{package_id}' ({manager}): {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
