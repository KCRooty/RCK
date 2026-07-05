# Catálogo de tweaks (firmado)

Cada archivo en `tweaks/**/*.yaml` describe un tweak siguiendo `catalog.schema.json`. El catálogo completo se firma con Ed25519 para que el Core en Rust (`src-tauri/src/signature.rs`) rechace cualquier catálogo modificado o corrupto al arrancar.

## Generar tu propio par de claves (una sola vez)

```bash
node scripts/sign-catalog.mjs --generate-keys
```

Esto crea:
- `catalog/private_key.pem` — **nunca se commitea** (está en `.gitignore`). Guárdala fuera del repo (gestor de secretos, USB offline, etc.).
- `catalog/public_key.pem` — sí se commitea. Es la que el binario de RCK usa para verificar.

## Firmar el catálogo

Cada vez que añadas o modifiques un tweak, hay que re-firmar:

```bash
node scripts/sign-catalog.mjs
```

Esto:
1. Recorre `catalog/tweaks/**/*.yaml` en orden alfabético.
2. Calcula el SHA-256 del contenido concatenado.
3. Firma ese hash con `private_key.pem`.
4. Escribe la firma (hex) en `catalog/catalog.sig`.

`catalog.sig` sí se commitea — es lo que el Core verifica en runtime junto con `public_key.pem`.

## Por qué

Mismo modelo que adoptó OptimizerNXT al pasar de app monolítica a motor CLI: un catálogo no firmado (o firmado con una clave que no coincide) se rechaza por completo, no se ejecuta "a medias". Esto evita que alguien inyecte un tweak malicioso modificando el YAML directamente en un fork, una descarga de terceros, o un catálogo comprometido servido remotamente en el futuro.
