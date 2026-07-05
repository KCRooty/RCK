use std::path::Path;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use crate::catalog::Risk;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolEntry {
    pub id: String,
    pub name: String,
    pub description: String,
    pub risk: Risk,
    #[serde(default)]
    pub requires_restart: bool,
    /// Archivo .ps1 en scripts/powershell/Tools/ que define la función.
    pub script: String,
    /// Función que ejecuta la acción. A diferencia de los tweaks, las
    /// herramientas son acciones puntuales: no tienen test/revert.
    pub run: String,
}

pub struct ToolCatalog {
    pub tools: Vec<ToolEntry>,
}

impl ToolCatalog {
    pub fn find(&self, id: &str) -> Option<&ToolEntry> {
        self.tools.iter().find(|t| t.id == id)
    }
}

pub fn load_tools(catalog_dir: &Path) -> Result<ToolCatalog> {
    let tools_dir = catalog_dir.join("tools");
    let mut tools = Vec::new();

    if tools_dir.exists() {
        let mut files: Vec<_> = std::fs::read_dir(&tools_dir)?
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().map(|e| e == "yaml" || e == "yml").unwrap_or(false))
            .collect();
        files.sort();

        for file in files {
            let content = std::fs::read_to_string(&file)
                .with_context(|| format!("no se pudo leer {}", file.display()))?;
            let entries: Vec<ToolEntry> = serde_yaml::from_str(&content)
                .with_context(|| format!("YAML inválido en {}", file.display()))?;
            tools.extend(entries);
        }
    }

    Ok(ToolCatalog { tools })
}
