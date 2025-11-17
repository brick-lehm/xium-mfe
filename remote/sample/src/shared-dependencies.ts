import {SharedConfigExtended} from "./types/shared-config.type";

export const sharedDependencies: Record<string, SharedConfigExtended> = {

    //  ================================================
    //  ▼ PJ固有依存
    //  ================================================

    //  ================================================
    //  ▼ 共通依存
    //  ================================================

    // フレームワーク（必須・singleton）
    react: {
        singleton: true,      // 型定義に無いが実行時には動作する
        requiredVersion: false
    },
    'react-dom': {
        singleton: true,
        requiredVersion: false
    },

    // 状態管理（singleton推奨）
    'swr': {
        singleton: true,
        requiredVersion: false
    },

    // UIライブラリ（singleton推奨）
    '@brick-lehm/xium-ui': {
        singleton: true,      // ThemeProvider共有のため
        requiredVersion: false,
        version: '2.9.0'      // package.jsonのexportsに含まれていないため明示指定
    },
    '@mui/material': {
        singleton: true,
        requiredVersion: false
    },
    '@emotion/react': {
        singleton: true,
        requiredVersion: false
    },
    '@emotion/styled': {
        singleton: true,
        requiredVersion: false
    }
};
