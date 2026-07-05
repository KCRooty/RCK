import type { AppEntry, PackageManager, ToolEntry, Tweak } from "./types";

export interface SelectedApp {
  app: AppEntry;
  manager: PackageManager;
}

export interface Selection {
  tweaks: Tweak[];
  apps: SelectedApp[];
  tools: ToolEntry[];
}

/**
 * Construye el .ps1 descargable para el modo web: incluye una vez el código
 * fuente de cada tweak/herramienta seleccionada (deduplicado por archivo),
 * seguido de las llamadas a sus funciones, y la instalación de las apps
 * elegidas vía winget/chocolatey. Pensado para correr con permisos de
 * administrador, igual que si se aplicara en vivo desde el escritorio.
 */
export function buildScript({ tweaks, apps, tools }: Selection): string {
  const lines: string[] = [
    "#Requires -RunAsAdministrator",
    "#Requires -Version 7.0",
    "",
    `# Generado por RCK (rck) el ${new Date().toISOString()}`,
    `# Tweaks: ${tweaks.map((t) => t.id).join(", ") || "ninguno"}`,
    `# Apps: ${apps.map((a) => a.app.id).join(", ") || "ninguna"}`,
    `# Herramientas: ${tools.map((t) => t.id).join(", ") || "ninguna"}`,
    "",
    "Write-Host 'Creando punto de restauracion...' -ForegroundColor Cyan",
    "Checkpoint-Computer -Description 'RCK' -RestorePointType 'MODIFY_SETTINGS'",
    "",
  ];

  const seenScripts = new Set<string>();
  for (const tweak of tweaks) {
    if (seenScripts.has(tweak.script)) continue;
    seenScripts.add(tweak.script);
    lines.push(`# --- ${tweak.script} ---`, tweak.psSource ?? "", "");
  }
  for (const tool of tools) {
    if (seenScripts.has(tool.script)) continue;
    seenScripts.add(tool.script);
    lines.push(`# --- ${tool.script} ---`, tool.psSource ?? "", "");
  }

  for (const tweak of tweaks) {
    lines.push(`Write-Host 'Aplicando ${tweak.id}...' -ForegroundColor Green`, tweak.apply, "");
  }

  for (const { app, manager } of apps) {
    const packageId = manager === "winget" ? app.winget : app.choco;
    if (!packageId) continue;
    lines.push(`Write-Host 'Instalando ${app.name} (${manager})...' -ForegroundColor Green`);
    lines.push(
      manager === "winget"
        ? `winget install --id ${packageId} --exact --silent --accept-package-agreements --accept-source-agreements`
        : `choco install ${packageId} -y`
    );
    lines.push("");
  }

  for (const tool of tools) {
    lines.push(`Write-Host 'Ejecutando ${tool.id}...' -ForegroundColor Green`, tool.run, "");
  }

  lines.push("Write-Host 'Listo.' -ForegroundColor Cyan");
  return lines.join("\n");
}

export function downloadScript(content: string, filename = "RCK-script.ps1"): void {
  const blob = new Blob([content], { type: "application/octet-stream" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
