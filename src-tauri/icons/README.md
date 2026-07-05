Los iconos actuales (`32x32.png`, `128x128.png`, `icon.ico`) son un placeholder genérico (cuadrado azul/oscuro) generado solo para que `tauri build` no falle por archivos faltantes. Reemplázalos por el logo real cuando lo tengas.

Cuando tengas un logo (PNG cuadrado, idealmente 1024x1024), genera el set completo con:

```bash
npx @tauri-apps/cli icon path/to/logo.png
```

Esto crea `32x32.png`, `128x128.png`, `icon.ico`, etc. en este directorio, tal como los referencia `src-tauri/tauri.conf.json`.
