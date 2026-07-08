// Previene que se abra una consola adicional en Windows en builds release.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod apps;
mod backup;
mod blacklist;
mod catalog;
mod commands;
mod guard;
mod signature;
mod system;
mod tools;

use std::sync::Mutex;

use tauri::Manager;

use commands::{AppCatalogState, CatalogState, ToolCatalogState};

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .setup(|app| {
            let scripts_dir = app
                .path()
                .resolve("scripts/powershell", tauri::path::BaseDirectory::Resource)
                .expect("la ruta de scripts/powershell debe resolverse");
            guard::scan_scripts_for_forbidden_patterns(&scripts_dir)
                .expect("ningún script de RCK puede contener un patrón prohibido (ver guard.rs)");

            let catalog = commands::load_initial_catalog(app.handle())
                .expect("el catálogo debe cargar y verificar su firma al arrancar");
            app.manage(CatalogState(Mutex::new(catalog)));

            let app_catalog = commands::load_initial_apps(app.handle())
                .expect("el catálogo de apps debe cargar correctamente al arrancar");
            app.manage(AppCatalogState(Mutex::new(app_catalog)));

            let tool_catalog = commands::load_initial_tools(app.handle())
                .expect("el catálogo de herramientas debe cargar correctamente al arrancar");
            app.manage(ToolCatalogState(Mutex::new(tool_catalog)));

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::list_tweaks,
            commands::get_tweak_status,
            commands::apply_tweak,
            commands::revert_tweak,
            commands::create_restore_point_cmd,
            commands::list_apps,
            commands::get_app_status,
            commands::install_app,
            commands::uninstall_app,
            commands::list_tools,
            commands::run_tool,
            commands::get_system_info,
        ])
        .run(tauri::generate_context!())
        .expect("error al ejecutar la aplicación RCK");
}
