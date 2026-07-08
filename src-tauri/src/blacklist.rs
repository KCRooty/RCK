/// Servicios que ningún tweak puede deshabilitar, ni en modo `expert`.
/// Ver `docs/BLACKLIST.md` para el razonamiento completo detrás de cada uno.
pub const BLACKLISTED_SERVICES: &[&str] = &[
    "WinDefend",
    "wuauserv",
    "EventLog",
    "RpcSs",
    "DcomLaunch",
    "Winmgmt",
    "bfe",
    "mpssvc",
    "TrustedInstaller",
    // Añadidos tras analizar Platinum Optimizer y Optimizer.json (ver
    // docs/BLACKLIST.md): todos protegen Windows Update o Defender/ATP.
    // Platinum Optimizer no solo deshabilita estos servicios, sino que
    // renombra sus DLLs con `takeown`/`icacls` para que no puedan
    // reactivarse ni reinstalarse — motivo por el que `guard.rs` prohíbe
    // `takeown`/`icacls` a nivel de script, no solo estos nombres.
    "WaaSMedicSvc",
    "UsoSvc",
    "uhssvc",
    "SecurityHealthService",
    "WdNisSvc",
    "Sense",
    "wscsvc",
];

/// Rutas de registro que ningún tweak puede escribir.
pub const BLACKLISTED_REGISTRY_PREFIXES: &[&str] = &[
    r"HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot",
    r"HKLM\SYSTEM\CurrentControlSet\Services\Tcpip",
    // Deshabilitar Defender por policy (en vez de por servicio) es la otra
    // vía que usan los "optimizadores" tierra quemada — bloqueada aquí
    // aunque el tweak declare targets.services vacío.
    r"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender",
];

pub fn is_service_blacklisted(service: &str) -> bool {
    BLACKLISTED_SERVICES
        .iter()
        .any(|s| s.eq_ignore_ascii_case(service))
}

pub fn is_registry_path_blacklisted(path: &str) -> bool {
    let normalized = path.to_ascii_uppercase();
    BLACKLISTED_REGISTRY_PREFIXES
        .iter()
        .any(|p| normalized.starts_with(&p.to_ascii_uppercase()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_blacklisted_service_case_insensitively() {
        assert!(is_service_blacklisted("windefend"));
        assert!(!is_service_blacklisted("Spooler"));
    }

    #[test]
    fn detects_blacklisted_registry_prefix() {
        assert!(is_registry_path_blacklisted(
            r"HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Option"
        ));
        assert!(!is_registry_path_blacklisted(
            r"HKCU\Software\Microsoft\Windows\CurrentVersion"
        ));
    }

    #[test]
    fn blocks_the_waas_medic_takeover_technique() {
        assert!(is_service_blacklisted("WaaSMedicSvc"));
        assert!(is_service_blacklisted("Sense"));
    }

    #[test]
    fn blocks_disabling_defender_via_policy_registry() {
        assert!(is_registry_path_blacklisted(
            r"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\DisableAntiSpyware"
        ));
    }
}
