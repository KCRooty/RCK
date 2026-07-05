/**
 * RCK corre en dos modos desde el mismo frontend:
 * - Desktop (Tauri): puede invocar IPC y aplicar tweaks en vivo.
 * - Web (navegador normal): no tiene acceso al sistema, así que en vez de
 *   aplicar nada, construye un .ps1 con los tweaks/apps elegidos para que
 *   el usuario lo descargue y lo corra él mismo (igual que WinScript).
 */
export function isDesktop(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}
