import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'
import env from "vite-plugin-env-compatible";
import {sharedDependencies} from "./src/shared-dependencies.ts";

const remotes = () => {
  const env = (process.env.ENV || 'local').toLowerCase();

  switch (env) {
    default: return {
      sample: 'http://localhost:3001/assets/remoteEntry.js',
    }
  }
};

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    env({prefix: 'VITE_', mountedPath: 'process.env'}),
    federation({
      name: 'app_shell',
      remotes: remotes(),
      shared: sharedDependencies,
    })
  ],
  resolve: {
    dedupe: Object.keys(sharedDependencies),
  },
  build: {
    modulePreload: false,
    target: 'esnext',
    minify: false,
    cssCodeSplit: false
  },
  server: {
    port: 3000,
    host: true,
    strictPort: true,
    origin: 'http://localhost:3000',
    hmr: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'X-Requested-With, content-type, Authorization',
    },
  },
  preview: {
    port: 3000,
    strictPort: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'X-Requested-With, content-type, Authorization',
    },
  }

})
