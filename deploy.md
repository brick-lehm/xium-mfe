# MFE デプロイマニュアル

## 概要

このプロジェクトでは、複数のMicro Frontend (MFE) を管理しています。
各MFEは共通のデプロイスクリプトを使用してビルド・デプロイが可能です。

## ディレクトリ構成

```
xium-mfe/
├── deploy/                          # 共通デプロイファイル
│   ├── Dockerfile                   # マルチステージビルド用Dockerfile
│   ├── docker-entrypoint.sh         # nginxエントリーポイント
│   ├── nginx.conf                   # nginx設定テンプレート
│   ├── docker_build_local.sh        # ローカルビルドスクリプト
│   └── docker_deploy.sh             # デプロイスクリプト
├── remote/                          # MFEプロジェクト群
│   ├── plan-form/                   # プラン選択フォームMFE
└── deploy.md                        # このファイル
```

## 前提条件

- Docker Desktop がインストールされていること
- pnpm がインストールされていること
- Docker Buildx が有効であること（マルチプラットフォームビルド時）
- プライベートパッケージへのアクセス用に `NODE_AUTH_TOKEN` が設定されていること

## 環境変数の設定

各MFEには環境別の `.env` ファイルを用意します：

```
remote/<MFE名>/
├── .env           # デフォルト環境変数
├── .env.dev       # 開発環境用
└── .env.prod      # 本番環境用
```

### 必須環境変数

- `NODE_AUTH_TOKEN`: プライベートパッケージへのアクセストークン
- その他、各MFE固有の環境変数（VITE_* など）

## ローカルビルド

### 基本的な使い方

```bash
# プロジェクトルートで実行
./deploy/docker_build_local.sh -pj <MFE名>
```

### オプション

- `-pj <MFE名>` (必須): ビルド対象のMFE名（例: `sample`）
- `-env <環境名>` (任意): 使用する環境設定（例: `dev`, `prod`）。省略時は `.env` を使用

### 使用例

```bash
# plan-formをデフォルト環境でビルド
./deploy/docker_build_local.sh -pj sample
```

### ビルド成功時の出力イメージ

```
ビルドが完了しました！

コンテナを起動するには:
  docker run -d -p 8080:80 --name sample-test mfe-sample:local

起動後にアクセス:
  http://localhost:8080/sample/assets/remoteEntry.js
  http://localhost:8080/sample/

コンテナを停止・削除するには:
  docker stop sample-test && docker rm sample-test
```

## ローカルでの動作確認

### コンテナの起動

```bash
# ビルドしたイメージからコンテナを起動
docker run -d -p 8080:80 --name <MFE名>-test mfe-<MFE名>:local

# 例: sample
docker run -d -p 8080:80 --name sample-test mfe-sample:local
```

### アクセス確認

```bash
# remoteEntry.jsへのアクセス確認（Module Federationのエントリーポイント）
curl -I http://localhost:8080/<MFE名>/assets/remoteEntry.js

# メインページへのアクセス確認
curl http://localhost:8080/<MFE名>/

# ヘルスチェック
curl http://localhost:8080/health

# レディネスチェック
curl http://localhost:8080/ready
```

### ブラウザでの確認

```
http://localhost:8080/<MFE名>/
http://localhost:8080/<MFE名>/assets/remoteEntry.js
```

### コンテナの停止・削除

```bash
docker stop <MFE名>-test && docker rm <MFE名>-test

# 例: sample
docker stop sample-test && docker rm sample-test
```

## 本番デプロイ

### 前提条件

- Docker Hubへのログインが完了していること
- マルチプラットフォームビルド用のbuildxが有効化されていること

```bash
# Docker Hubへログイン
docker login

# buildxの確認
docker buildx ls
```

### デプロイコマンド

```bash
./deploy/docker_deploy.sh -pj <MFE名> [-env <環境名>]
```

### 使用例

```bash
# sampleを本番環境でデプロイ
./deploy/docker_deploy.sh -pj sample -env prod
```

### デプロイの動作

1. 指定された環境の `.env` ファイルを読み込み
2. マルチプラットフォーム（linux/amd64, linux/arm64）でビルド
3. Docker Hubに `xiumjp/mfe-<MFE名>:latest` としてプッシュ

## Kubernetes (k8s) デプロイ

各MFEのK8sマニフェストは、それぞれのMFEディレクトリ配下に配置されています：

```
remote/<MFE名>/deploy/dev/
├── deployment.yaml
├── service.yaml
└── ingress.yaml
```

### K8sへのデプロイ手順

```bash
# マニフェストの適用
kubectl apply -f remote/<MFE名>/deploy/dev/

# 例: sample
kubectl apply -f remote/sample/deploy/dev/
```

## トラブルシューティング

### ビルドエラー: `.env.xxx` が見つからない

**原因**: 指定した環境名の `.env` ファイルが存在しない

**解決方法**:
```bash
# 利用可能な.envファイルを確認
ls -la remote/<MFE名>/.env*

# 正しい環境名を指定
./deploy/docker_build_local.sh -pj <MFE名> -env dev
```

### ビルドエラー: `NODE_AUTH_TOKEN` が設定されていません

**原因**: プライベートパッケージへのアクセストークンが未設定

**解決方法**:
```bash
# .envファイルにNODE_AUTH_TOKENを追加
echo "NODE_AUTH_TOKEN=your_token_here" >> remote/<MFE名>/.env

# または環境変数として設定
export NODE_AUTH_TOKEN=your_token_here
./deploy/docker_build_local.sh -pj <MFE名>
```

### コンテナが起動しない

**確認事項**:
```bash
# コンテナログの確認
docker logs <MFE名>-test

# nginx設定の確認
docker exec <MFE名>-test cat /etc/nginx/conf.d/default.conf

# ポートの競合確認
lsof -i :8080
```

### remoteEntry.jsにアクセスできない

**確認事項**:
1. コンテナが正常に起動しているか
   ```bash
   docker ps | grep <MFE名>
   ```

2. nginx設定でAPP_NAMEが正しく置換されているか
   ```bash
   docker logs <MFE名>-test | grep "Configuring nginx"
   ```

3. 正しいパスでアクセスしているか
   ```bash
   # 正: http://localhost:8080/<MFE名>/assets/remoteEntry.js
   # 誤: http://localhost:8080/assets/remoteEntry.js
   ```

## 新しいMFEの追加

新しいMFEを追加する場合の手順：

### 1. MFEディレクトリの作成

```bash
mkdir -p remote/<新しいMFE名>
cd remote/<新しいMFE名>

# Viteプロジェクトの初期化
pnpm create vite . --template react-ts
```

### 2. 環境変数ファイルの作成

```bash
# デフォルト環境
cat > .env << EOF
NODE_AUTH_TOKEN=\${NODE_AUTH_TOKEN}
VITE_APP_NAME=<新しいMFE名>
EOF

# 開発環境
cat > .env.dev << EOF
NODE_AUTH_TOKEN=\${NODE_AUTH_TOKEN}
VITE_APP_NAME=<新しいMFE名>
VITE_API_URL=https://dev-api.example.com
EOF

# 本番環境
cat > .env.prod << EOF
NODE_AUTH_TOKEN=\${NODE_AUTH_TOKEN}
VITE_APP_NAME=<新しいMFE名>
VITE_API_URL=https://api.example.com
EOF
```

### 3. .dockerignoreの作成

```bash
cat > .dockerignore << EOF
node_modules
dist
.git
*.md
.env.local
.DS_Store
EOF
```

### 4. Module Federationの設定

`vite.config.ts` でModule Federationを設定してください。

### 5. ビルドとテスト

```bash
# プロジェクトルートに戻る
cd ../..

# ビルド
./deploy/docker_build_local.sh -pj <新しいMFE名>

# テスト
docker run -d -p 8080:80 --name <新しいMFE名>-test mfe-<新しいMFE名>:local
curl -I http://localhost:8080/<新しいMFE名>/assets/remoteEntry.js
```

## ベストプラクティス

### 1. 環境変数の管理

- `.env` ファイルは Git にコミットしない（`.gitignore` に追加）
- `.env.example` を用意して必要な変数を文書化
- 機密情報は環境変数経由で注入

### 2. イメージタグの管理

本番環境では `latest` タグだけでなく、バージョンタグも使用することを推奨：

```bash
# タグ付きイメージのビルド例
docker tag mfe-sample:local xiumjp/mfe-sample:v1.0.0
docker push xiumjp/mfe-sample:v1.0.0
```

### 3. キャッシュの活用

- Dockerのビルドキャッシュを活用するため、依存関係の変更が少ない場合は `--no-cache` を外す
- pnpmのstore pruneでキャッシュを削減

### 4. セキュリティ

- NODE_AUTH_TOKENなどの機密情報は環境変数で管理
- イメージビルド後は `.npmrc` を削除（Dockerfile内で実施済み）
- 本番イメージには開発用依存関係を含めない

## 参考情報

### nginx設定の詳細

- Gzip圧縮: 有効（最小1024バイト）
- CORS: すべてのオリジンを許可
- キャッシュ:
  - 静的アセット: 1年
  - remoteEntry.js: キャッシュ無効
- ヘルスチェック: `/health`, `/ready` エンドポイント

### Dockerfileの構成

- マルチステージビルド採用
- ステージ1（builder）: Node.js 20 Alpine でビルド
- ステージ2（production）: nginx Alpine でホスティング
- 最終イメージサイズ: 約50-60MB（MFEのサイズにより変動）

### ポート設定

- コンテナ内: 80番ポート
- ローカルテスト時: 8080番ポートにマッピング
- 本番環境: Ingress経由でアクセス

---

最終更新日: 2025-11-01
