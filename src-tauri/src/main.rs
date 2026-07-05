// Previene que se abra una consola adicional en Windows en builds release.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod backup;
mod blacklist;
mod catalog;
mod commands;
mod signature;

use std::sync::Mutex;

use commands::CatalogState;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .setup(|app| {
            let catalog = commands::load_initial_catalog(&app.handle())
                .expect("el catálogo debe cargar y verificar su firma al arrancar");
            app.manage(CatalogState(Mutex::new(catalog)));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::list_tweaks,
            commands::get_tweak_status,
            commands::apply_tweak,
            commands::revert_tweak,
            commands::create_restore_point_cmd,
        ])
        .run(tauri::generate_context!())
        .expect("error al ejecutar la aplicación RCK");
}
