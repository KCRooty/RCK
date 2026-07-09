use std::path::Path;

use anyhow::{bail, Context, Result};

/// Patrones de comandos que ningún script `.ps1` de RCK puede contener, pase
/// lo que pase. No es una lista de "cosas peligrosas en general" — es una
/// lista derivada de analizar herramientas "tierra quemada" reales
/// (Platinum Optimizer, entre otras) que causaron daño irreversible:
///
/// - `takeown` / `icacls ... /grant` sobre archivos protegidos: la técnica
///   que Platinum Optimizer usa para renombrar DLLs de Windows Update
///   (`WaaSMedicSvc.dll`, `wuaueng.dll`) y saltarse los permisos de
///   TrustedInstaller. RCK nunca debe tocar la propiedad/ACL de un archivo
///   del sistema — punto.
/// - `bcdedit /set` sobre banderas de seguridad de arranque (DEP/NX,
///   hypervisor, VBS): Platinum Optimizer las desactiva para "rendimiento".
///   Nada en el catálogo de RCK justifica tocar el boot loader.
/// - Borrado recursivo forzado (`Remove-Item -Recurse -Force`, `rd /s`,
///   `del /s /f`) apuntando a `System32`, `DriverStore` o `Windows.old`:
///   coincide con cómo Platinum Optimizer borra archivos de telemetría de
///   NVIDIA a base de eliminar directorios completos del driver store.
/// - `net user ... /delete`: borra cuentas de Windows sin pasar por ningún
///   flujo de confirmación de RCK.
/// - `diskpart`, `format `, `vssadmin delete shadows`: pueden destruir datos
///   de forma no reversible y no tienen cabida en un catálogo de tweaks.
const FORBIDDEN_PATTERNS: &[&str] = &[
    "takeown",
    "icacls",
    "bcdedit",
    "diskpart",
    "vssadmin delete",
    "net user",
    "format c:",
    "cipher /w",
];

/// Rutas que ningún tweak puede borrar/mover, sin importar los flags que use
/// (`-Recurse -Force`, `/s /q`...). A diferencia de `FORBIDDEN_PATTERNS`,
/// esto no prohíbe el verbo de borrado en sí — herramientas legítimas como
/// `Clear-TempFiles.ps1` necesitan `Remove-Item -Recurse -Force` sobre
/// `$env:TEMP`. Lo que se prohíbe es combinar un verbo de borrado con una de
/// estas rutas en la misma línea.
const DELETE_VERBS: &[&str] = &["remove-item", "del ", "erase ", "rd ", "rmdir"];
const PROTECTED_DELETE_PATHS: &[&str] = &[
    "system32",
    "syswow64",
    "driverstore",
    "windows.old",
    "windowsapps",
    "programdata\\microsoft\\windows defender",
];

/// Recorre recursivamente todos los `.ps1` bajo `scripts_dir` (Tweaks/ y
/// Tools/) y falla si alguno contiene un patrón prohibido. Se ejecuta una
/// vez al arrancar la app, antes de que el catálogo quede disponible para la
/// UI — es una defensa adicional a la lista negra de servicios/registro:
/// esa valida los `targets` declarados en el YAML, esto valida el contenido
/// real del script que se va a ejecutar.
pub fn scan_scripts_for_forbidden_patterns(scripts_dir: &Path) -> Result<()> {
    if !scripts_dir.exists() {
        return Ok(());
    }

    for path in walk_ps1_files(scripts_dir)? {
        let content = std::fs::read_to_string(&path)
            .with_context(|| format!("no se pudo leer {}", path.display()))?;
        check_content(&content)
            .with_context(|| format!("rechazado en '{}'", path.display()))?;
    }

    Ok(())
}

/// Misma comprobación que `scan_scripts_for_forbidden_patterns`, pero sobre
/// un string en memoria en vez de archivos del catálogo. La usa
/// `commands::run_raw_script` para el editor de "Ejecutar script": el
/// usuario puede escribir/editar lo que quiera, pero antes de correrlo con
/// permisos de administrador se comprueba contra los mismos patrones
/// prohibidos que ya protegen al catálogo firmado. No es una sandbox
/// completa — es la misma defensa de última línea que el resto de RCK,
/// aplicada también aquí en vez de confiar ciegamente en el texto pegado.
pub fn check_content(content: &str) -> Result<()> {
    let lowercase = content.to_ascii_lowercase();

    for pattern in FORBIDDEN_PATTERNS {
        if lowercase.contains(pattern) {
            bail!(
                "contiene el patrón prohibido '{pattern}' — RCK nunca ejecuta este comando (ver guard.rs)"
            );
        }
    }

    for line in lowercase.lines() {
        let has_delete_verb = DELETE_VERBS.iter().any(|v| line.contains(v));
        if !has_delete_verb {
            continue;
        }
        for protected in PROTECTED_DELETE_PATHS {
            if line.contains(protected) {
                bail!("intenta borrar algo bajo la ruta protegida '{protected}' — rechazado (ver guard.rs)");
            }
        }
    }

    Ok(())
}

fn walk_ps1_files(dir: &Path) -> Result<Vec<std::path::PathBuf>> {
    let mut out = Vec::new();
    for entry in std::fs::read_dir(dir).with_context(|| format!("no se pudo leer {}", dir.display()))? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            out.extend(walk_ps1_files(&path)?);
        } else if path.extension().map(|e| e == "ps1").unwrap_or(false) {
            out.push(path);
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn passes_on_the_real_committed_scripts() {
        let dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../scripts/powershell");
        scan_scripts_for_forbidden_patterns(&dir)
            .expect("ningún script real del repo debe contener un patrón prohibido");
    }

    #[test]
    fn rejects_a_script_using_takeown() {
        let tmp = std::env::temp_dir().join(format!("rck-guard-test-{}", std::process::id()));
        std::fs::create_dir_all(&tmp).unwrap();
        let bad_script = tmp.join("Bad.ps1");
        std::fs::write(&bad_script, "takeown /f C:\\Windows\\System32\\evil.dll").unwrap();

        let result = scan_scripts_for_forbidden_patterns(&tmp);

        std::fs::remove_dir_all(&tmp).ok();
        assert!(result.is_err());
    }

    #[test]
    fn check_content_rejects_raw_script_with_forbidden_pattern() {
        assert!(check_content("bcdedit /set hypervisorlaunchtype off").is_err());
        assert!(check_content("Remove-Item -Recurse -Force C:\\Windows\\System32\\drivers").is_err());
    }

    #[test]
    fn check_content_allows_benign_script() {
        assert!(check_content("Write-Host 'hola'; Get-Service | Select-Object -First 5").is_ok());
    }
}
