import {defineConfig} from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'
import env from "vite-plugin-env-compatible";
import {sharedDependencies} from "./src/shared-dependencies.ts";

// 設定
const port = 3001;

// https://vite.dev/config/
export default defineConfig({
    plugins: [
        react(),
        env({mountedPath: 'process.env', prefix: 'VITE_',}),
        federation({
            // モジュール名
            name: 'sample',
            filename: 'remoteEntry.js',
            exposes: {
                // '外部公開コンポーネント名': '外部公開コンポーネントアドレス'
                './Sample': './src/exposes/Sample',
            },
            shared: sharedDependencies,
        })
    ],
    resolve: {
        dedupe: Object.keys(sharedDependencies),
    },
    build: {
        assetsDir: 'assets',
        modulePreload: false,
        target: 'esnext',
        minify: false,
        cssCodeSplit: false,
        rollupOptions: {
            output: {
                manualChunks: undefined
            }
        }
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
