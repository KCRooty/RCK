#!/usr/bin/env node
import { generateKeyPairSync, sign, createHash } from "node:crypto";
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";

const catalogDir = resolve(fileURLToPath(import.meta.url), "../../catalog");
const tweaksDir = join(catalogDir, "tweaks");
const appsDir = join(catalogDir, "apps");
const privateKeyPath = join(catalogDir, "private_key.pem");
const publicKeyPath = join(catalogDir, "public_key.pem");
const signaturePath = join(catalogDir, "catalog.sig");

function generateKeys() {
  const { publicKey, privateKey } = generateKeyPairSync("ed25519", {
    publicKeyEncoding: { type: "spki", format: "pem" },
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
  });
  writeFileSync(privateKeyPath, privateKey, { mode: 0o600 });
  writeFileSync(publicKeyPath, publicKey);
  console.log(`Claves generadas:\n  privada: ${privateKeyPath} (NO commitear)\n  pública: ${publicKeyPath}`);
}

function collectYamlFiles(dir) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      out.push(...collectYamlFiles(full));
    } else if ([".yaml", ".yml"].includes(extname(full))) {
      out.push(full);
    }
  }
  return out.sort();
}

function hashCatalog() {
  // Cubre tanto tweaks/ como apps/: todo el catálogo se firma como una sola
  // unidad, igual que lo verifica src-tauri/src/signature.rs.
  const files = [...collectYamlFiles(tweaksDir), ...collectYamlFiles(appsDir)].sort();
  if (files.length === 0) {
    throw new Error(`No se encontraron archivos de catálogo en ${tweaksDir} ni ${appsDir}`);
  }
  const hash = createHash("sha256");
  for (const file of files) {
    hash.update(readFileSync(file));
  }
  console.log(`Firmando ${files.length} tweak(s):`);
  files.forEach((f) => console.log(`  - ${f.replace(catalogDir, "catalog")}`));
  return hash.digest();
}

function signCatalog() {
  if (!existsSync(privateKeyPath)) {
    throw new Error(
      `No existe ${privateKeyPath}. Ejecuta primero: node scripts/sign-catalog.mjs --generate-keys`
    );
  }
  const privateKey = readFileSync(privateKeyPath, "utf8");
  const digest = hashCatalog();
  const signature = sign(null, digest, privateKey);
  writeFileSync(signaturePath, signature.toString("hex"));
  console.log(`Firma escrita en ${signaturePath}`);
}

const args = process.argv.slice(2);
if (args.includes("--generate-keys")) {
  generateKeys();
} else {
  signCatalog();
}
