use std::path::Path;

use anyhow::{bail, Context, Result};
use ed25519_dalek::{Signature, Verifier, VerifyingKey};
use sha2::{Digest, Sha256};

/// Verifica que `catalog_dir/catalog.sig` sea una firma Ed25519 válida, hecha
/// con la clave privada correspondiente a `catalog_dir/public_key.pem`, sobre
/// el hash SHA-256 del contenido canónico de todos los tweaks.
///
/// Esto evita que un catálogo modificado (por un tercero, o corrupto) se
/// cargue silenciosamente. Ver `scripts/sign-catalog.mjs` para cómo se genera
/// la firma.
pub fn verify_catalog(catalog_dir: &Path) -> Result<()> {
    let public_key_pem = std::fs::read_to_string(catalog_dir.join("public_key.pem"))
        .context("no se encontró catalog/public_key.pem")?;
    let signature_hex = std::fs::read_to_string(catalog_dir.join("catalog.sig"))
        .context("no se encontró catalog/catalog.sig — el catálogo debe firmarse antes de distribuirse")?;

    let verifying_key = parse_public_key(&public_key_pem)?;
    let signature = parse_signature(signature_hex.trim())?;

    // Cubre catalog/tweaks/, catalog/apps/ y catalog/tools/: todo el
    // catálogo se firma como una sola unidad, no solo los tweaks.
    let hash = hash_catalog(catalog_dir)?;

    verifying_key
        .verify(&hash, &signature)
        .context("la firma no coincide con el contenido actual del catálogo")?;

    Ok(())
}

fn hash_catalog(catalog_dir: &Path) -> Result<[u8; 32]> {
    let mut files = Vec::new();
    collect_yaml_files(&catalog_dir.join("tweaks"), &mut files)?;
    collect_yaml_files(&catalog_dir.join("apps"), &mut files)?;
    collect_yaml_files(&catalog_dir.join("tools"), &mut files)?;
    files.sort();

    let mut hasher = Sha256::new();
    for file in files {
        let content = std::fs::read(&file)?;
        hasher.update(&content);
    }
    Ok(hasher.finalize().into())
}

fn collect_yaml_files(dir: &Path, out: &mut Vec<std::path::PathBuf>) -> Result<()> {
    if !dir.exists() {
        return Ok(());
    }
    for entry in std::fs::read_dir(dir)? {
        let path = entry?.path();
        if path.is_dir() {
            collect_yaml_files(&path, out)?;
        } else if path.extension().map(|e| e == "yaml" || e == "yml").unwrap_or(false) {
            out.push(path);
        }
    }
    Ok(())
}

fn parse_public_key(pem: &str) -> Result<VerifyingKey> {
    let der = pem_to_bytes(pem)?;
    // Las claves Ed25519 en formato SPKI DER tienen un prefijo de 12 bytes
    // antes de los 32 bytes de la clave pública raw.
    if der.len() < 32 {
        bail!("clave pública inválida");
    }
    let raw = &der[der.len() - 32..];
    let bytes: [u8; 32] = raw.try_into().context("clave pública con longitud inesperada")?;
    VerifyingKey::from_bytes(&bytes).context("no se pudo parsear la clave pública Ed25519")
}

fn parse_signature(hex_str: &str) -> Result<Signature> {
    let bytes = hex_decode(hex_str)?;
    let arr: [u8; 64] = bytes.try_into().map_err(|_| anyhow::anyhow!("firma con longitud inválida"))?;
    Ok(Signature::from_bytes(&arr))
}

fn pem_to_bytes(pem: &str) -> Result<Vec<u8>> {
    let body: String = pem
        .lines()
        .filter(|l| !l.starts_with("-----"))
        .collect();
    base64_decode(&body)
}

fn base64_decode(s: &str) -> Result<Vec<u8>> {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD
        .decode(s)
        .context("base64 inválido en la clave pública")
}

fn hex_decode(s: &str) -> Result<Vec<u8>> {
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).context("hex inválido en la firma"))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    fn real_catalog_dir() -> std::path::PathBuf {
        std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../catalog")
    }

    #[test]
    fn verifies_the_committed_catalog_signature() {
        // El catálogo real del repo, firmado con `scripts/sign-catalog.mjs`,
        // debe verificar correctamente. Si este test falla, alguien editó un
        // YAML de catalog/ sin volver a firmar.
        verify_catalog(&real_catalog_dir()).expect("la firma del catálogo committeado debe ser válida");
    }

    #[test]
    fn rejects_a_tampered_catalog() {
        let src = real_catalog_dir();
        let tmp = std::env::temp_dir().join(format!("rck-sig-test-{}", std::process::id()));
        let _ = fs::remove_dir_all(&tmp);
        copy_dir(&src, &tmp).expect("no se pudo copiar el catálogo a un directorio temporal");

        // Modifica el contenido de un tweak sin re-firmar.
        let tampered = tmp.join("tweaks/privacy/disable-telemetry.yaml");
        let mut content = fs::read_to_string(&tampered).unwrap();
        content.push_str("\n# manipulado\n");
        fs::write(&tampered, content).unwrap();

        let result = verify_catalog(&tmp);
        fs::remove_dir_all(&tmp).ok();

        assert!(result.is_err(), "un catálogo modificado sin re-firmar debe rechazarse");
    }

    fn copy_dir(src: &Path, dst: &Path) -> std::io::Result<()> {
        fs::create_dir_all(dst)?;
        for entry in fs::read_dir(src)? {
            let entry = entry?;
            let target = dst.join(entry.file_name());
            if entry.file_type()?.is_dir() {
                copy_dir(&entry.path(), &target)?;
            } else {
                fs::copy(entry.path(), &target)?;
            }
        }
        Ok(())
    }
}
