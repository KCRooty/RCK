Iconos pendientes de generar.

Cuando tengas un logo (PNG cuadrado, idealmente 1024x1024), genera el set completo con:

```bash
npx @tauri-apps/cli icon path/to/logo.png
```

Esto crea `32x32.png`, `128x128.png`, `icon.ico`, etc. en este directorio, tal como los referencia `src-tauri/tauri.conf.json`.
