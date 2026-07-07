#!/usr/bin/env node
// Genera src/data/catalog.generated.json a partir de catalog/**/*.yaml y de
// las fuentes .ps1 de scripts/powershell/Tweaks/. Este JSON es lo único que
// el frontend necesita para renderizar la lista de tweaks/apps y, en modo
// web (fuera de Tauri), para construir el script .ps1 descargable.
import { parse } from "yaml";
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync, mkdirSync } from "node:fs";
import { join, resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(fileURLToPath(import.meta.url), "../..");
const catalogDir = join(root, "catalog");
const tweaksYamlDir = join(catalogDir, "tweaks");
const appsYamlDir = join(catalogDir, "apps");
const toolsYamlDir = join(catalogDir, "tools");
const tweaksScriptDir = join(root, "scripts", "powershell", "Tweaks");
const toolsScriptDir = join(root, "scripts", "powershell", "Tools");
const presetsFile = join(catalogDir, "presets.yaml");
const outDir = join(root, "src", "data");
const outFile = join(outDir, "catalog.generated.json");

function collectFiles(dir, exts) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      out.push(...collectFiles(full, exts));
    } else if (exts.includes(extname(full))) {
      out.push(full);
    }
  }
  return out.sort();
}

function loadTweaks() {
  const files = collectFiles(tweaksYamlDir, [".yaml", ".yml"]);
  return files.map((file) => {
    const tweak = parse(readFileSync(file, "utf8"));
    const scriptPath = join(tweaksScriptDir, tweak.script);
    if (!existsSync(scriptPath)) {
      throw new Error(`El tweak '${tweak.id}' referencia '${tweak.script}', que no existe en ${tweaksScriptDir}`);
    }
    return { ...tweak, psSource: readFileSync(scriptPath, "utf8") };
  });
}

function loadApps() {
  const files = collectFiles(appsYamlDir, [".yaml", ".yml"]);
  return files.flatMap((file) => parse(readFileSync(file, "utf8")));
}

function loadTools() {
  const files = collectFiles(toolsYamlDir, [".yaml", ".yml"]);
  return files.flatMap((file) => parse(readFileSync(file, "utf8"))).map((tool) => {
    const scriptPath = join(toolsScriptDir, tool.script);
    if (!existsSync(scriptPath)) {
      throw new Error(`La herramienta '${tool.id}' referencia '${tool.script}', que no existe en ${toolsScriptDir}`);
    }
    return { ...tool, psSource: readFileSync(scriptPath, "utf8") };
  });
}

function loadPresets(knownIds) {
  if (!existsSync(presetsFile)) return [];
  const presets = parse(readFileSync(presetsFile, "utf8"));
  for (const preset of presets) {
    for (const id of [...preset.tweaks, ...preset.apps, ...preset.tools]) {
      if (!knownIds.has(id)) {
        throw new Error(`El preset '${preset.id}' referencia '${id}', que no existe en el catálogo`);
      }
    }
  }
  return presets;
}

function main() {
  const tweaks = loadTweaks();
  const apps = loadApps();
  const tools = loadTools();

  const knownIds = new Set([...tweaks, ...apps, ...tools].map((entry) => entry.id));
  const presets = loadPresets(knownIds);

  mkdirSync(outDir, { recursive: true });
  writeFileSync(
    outFile,
    JSON.stringify({ generatedAt: new Date().toISOString(), tweaks, apps, tools, presets }, null, 2)
  );

  console.log(
    `Catálogo web generado: ${tweaks.length} tweak(s), ${apps.length} app(s), ${tools.length} herramienta(s), ${presets.length} preset(s) -> ${outFile}`
  );
}

main();
