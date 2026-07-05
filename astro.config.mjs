import { defineConfig } from 'astro/config';

// https://v2.tauri.app/start/frontend/astro/
export default defineConfig({
  output: 'static',
  vite: {
    clearScreen: false,
    envPrefix: ['VITE_', 'TAURI_'],
    server: {
      strictPort: true,
    },
  },
});
