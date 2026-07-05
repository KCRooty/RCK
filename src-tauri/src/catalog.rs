use std::path::Path;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use crate::signature;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Risk {
    Safe,
    Moderate,
    Advanced,
    Expert,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Targets {
    #[serde(default)]
    pub services: Vec<String>,
    #[serde(default)]
    pub registry: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tweak {
    pub id: String,
    pub category: String,
    pub risk: Risk,
    #[serde(default)]
    pub requires_restart: bool,
    pub description: String,
    /// Servicios/rutas de registro que este tweak toca, usado para validar
    /// contra la lista negra antes de invocar el motor PowerShell.
    #[serde(default)]
    pub targets: Targets,
    /// Archivo .ps1 en scripts/powershell/Tweaks/ que define las funciones.
    pub script: String,
    /// Nombre de la función PowerShell que aplica el tweak.
    pub apply: String,
    /// Nombre de la función PowerShell que revierte el tweak.
    pub revert: String,
    /// Nombre de la función PowerShell que comprueba si ya está aplicado.
    pub test: String,
}

pub struct Catalog {
    pub tweaks: Vec<Tweak>,
}

impl Catalog {
    pub fn find(&self, id: &str) -> Option<&Tweak> {
        self.tweaks.iter().find(|t| t.id == id)
    }

    pub fn by_category<'a>(&'a self, category: &str) -> Vec<&'a Tweak> {
        self.tweaks.iter().filter(|t| t.category == category).collect()
    }
}

/// Carga el catálogo desde `catalog_dir/tweaks/**/*.yaml`, rechazándolo si la
/// firma Ed25519 en `catalog_dir/catalog.sig` no coincide con el contenido.
pub fn load_catalog(catalog_dir: &Path) -> Result<Catalog> {
    signature::verify_catalog(catalog_dir)
        .context("firma del catálogo inválida: se rechaza la carga por seguridad")?;

    let tweaks_dir = catalog_dir.join("tweaks");
    let mut tweaks = Vec::new();

    for entry in walk_yaml_files(&tweaks_dir)? {
        let content = std::fs::read_to_string(&entry)
            .with_context(|| format!("no se pudo leer {}", entry.display()))?;
        let tweak: Tweak = serde_yaml::from_str(&content)
            .with_context(|| format!("YAML inválido en {}", entry.display()))?;
        tweaks.push(tweak);
    }

    Ok(Catalog { tweaks })
}

fn walk_yaml_files(dir: &Path) -> Result<Vec<std::path::PathBuf>> {
    let mut files = Vec::new();
    if !dir.exists() {
        return Ok(files);
    }
    for entry in walkdir(dir)? {
        if entry.extension().map(|e| e == "yaml" || e == "yml").unwrap_or(false) {
            files.push(entry);
        }
    }
    files.sort();
    Ok(files)
}

fn walkdir(dir: &Path) -> Result<Vec<std::path::PathBuf>> {
    let mut out = Vec::new();
    for entry in std::fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            out.extend(walkdir(&path)?);
        } else {
            out.push(path);
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loads_the_real_catalog_and_finds_a_known_tweak() {
        let dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../catalog");
        let catalog = load_catalog(&dir).expect("el catálogo real del repo debe cargar y verificar su firma");

        assert!(!catalog.tweaks.is_empty());
        let telemetry = catalog
            .find("privacy.disable-telemetry")
            .expect("el tweak de ejemplo debe existir en el catálogo");
        assert_eq!(telemetry.category, "privacy");
        assert_eq!(telemetry.risk, Risk::Safe);
    }
}
