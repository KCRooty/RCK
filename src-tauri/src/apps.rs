use std::path::Path;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppEntry {
    pub id: String,
    pub name: String,
    pub description: String,
    pub subcategory: String,
    pub winget: Option<String>,
    pub choco: Option<String>,
}

pub struct AppCatalog {
    pub apps: Vec<AppEntry>,
}

impl AppCatalog {
    pub fn find(&self, id: &str) -> Option<&AppEntry> {
        self.apps.iter().find(|a| a.id == id)
    }

    pub fn by_subcategory<'a>(&'a self, subcategory: &str) -> Vec<&'a AppEntry> {
        self.apps.iter().filter(|a| a.subcategory == subcategory).collect()
    }
}

/// A diferencia de los tweaks, el catálogo de apps no lleva scriptblocks
/// propios: la instalación/desinstalación se hace con las funciones
/// genéricas `Invoke-InstallApp`/`Invoke-UninstallApp` del motor, pasando el
/// identificador de winget o chocolatey. La firma del catálogo (verificada
/// en `signature::verify_catalog`, que cubre todo `catalog/`) protege este
/// archivo igual que a los tweaks.
pub fn load_apps(catalog_dir: &Path) -> Result<AppCatalog> {
    let apps_dir = catalog_dir.join("apps");
    let mut apps = Vec::new();

    if apps_dir.exists() {
        let mut files: Vec<_> = std::fs::read_dir(&apps_dir)?
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().map(|e| e == "yaml" || e == "yml").unwrap_or(false))
            .collect();
        files.sort();

        for file in files {
            let content = std::fs::read_to_string(&file)
                .with_context(|| format!("no se pudo leer {}", file.display()))?;
            let entries: Vec<AppEntry> = serde_yaml::from_str(&content)
                .with_context(|| format!("YAML inválido en {}", file.display()))?;
            apps.extend(entries);
        }
    }

    Ok(AppCatalog { apps })
}
