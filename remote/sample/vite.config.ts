import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'
import env from "vite-plugin-env-compatible";

// 設定
const port = 3001;

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    env({ mountedPath: 'process.env', prefix: 'VITE_',  }),
    federation({
      // モジュール名
      name: 'sample',
      filename: 'remoteEntry.js',
      exposes: {
        // '外部公開コンポーネント名': '外部公開コンポーネントアドレス'
        './Sample': './src/exposes/Sample'
      },
      shared: {
        react: {  },
        'react-dom': {  },

        '@mui/material': {},
        '@emotion/react': {},
        '@emotion/styled': {}
      }
    })
  ],
  build: {
    assetsDir: 'assets',
    modulePreload: false,
    target: 'esnext',
    minify: false,
    cssCodeSplit: false
  },
  server: {
    port: port,
    strictPort: true,
    origin: `http://localhost:${port}`,
    hmr: {
      clientPort: port,
    },
    headers: {
      'Access-Control-Allow-Origin': '*',
    },
  },
  preview: {
    port: port,
    strictPort: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
    },
  }
})
