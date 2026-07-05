import { defineConfig } from 'astro/config';

// https://v2.tauri.app/start/frontend/astro/
export default defineConfig({
  output: 'static',
  // Rutas planas (app.html en vez de app/index.html): más simple de
  // referenciar desde tauri.conf.json y desde los links de la landing.
  build: {
    format: 'file',
  },
  vite: {
    clearScreen: false,
    envPrefix: ['VITE_', 'TAURI_'],
    server: {
      strictPort: true,
    },
  },
});
