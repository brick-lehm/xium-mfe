# デプロイスクリプトについて

このディレクトリには、MFEのDockerイメージをビルド・デプロイするためのシェルスクリプトが含まれています。

## 利用可能なスクリプト

### docker_build_local.sh

ローカル環境でDockerイメージをビルドするためのスクリプトです。

**使い方:**
```bash
# デフォルト環境（.envを使用）
bash remote/recurring-billing-form/deploy/docker_build_local.sh

# 環境を指定してビルド（.env.prodを使用）
bash remote/recurring-billing-form/deploy/docker_build_local.sh -env prod
```

**機能:**
- アプリ名を自動検出（スクリプトの配置場所から判定）
- .envファイルから環境変数を自動読み込み
- `-env`オプションで環境別の.envファイルを指定可能（例: `-env prod` → `.env.prod`）
- 読み込んだ環境変数を全て`--build-arg`として展開
- ビルド完了後、コンテナ起動方法を表示

**出力イメージ:** `mfe-{アプリ名}:local`

---

### docker_deploy.sh

本番環境へDockerイメージをデプロイするためのスクリプトです。

**使い方:**
```bash
# デフォルト環境（.envを使用）
bash remote/recurring-billing-form/deploy/docker_deploy.sh

# 本番環境（.env.prodを使用）
bash remote/recurring-billing-form/deploy/docker_deploy.sh -env prod
```

**機能:**
- マルチプラットフォームビルド（linux/amd64, linux/arm64）
- Docker Hubへの自動プッシュ
- `--no-cache`オプションで常に最新のビルドを保証
- 必須環境変数（NODE_AUTH_TOKEN）のチェック

**出力イメージ:** `xiumjp/mfe-{アプリ名}:latest`

**注意:** Docker Hubへのプッシュには認証が必要です。事前に`docker login`を実行してください。

---

## 環境変数の設定方法

### 1. .envファイルを使用（推奨）

アプリディレクトリに`.env`ファイルを作成してください：

```bash
# remote/recurring-billing-form/.env
VITE_ENV=LOCAL
VITE_STRIPE_PUBLIC_KEY=pk_test_xxxxx
VITE_PAYMENT_ORIGIN=http://payment-gateway.dev.local
VITE_ACCESS_TOKEN=your_access_token
NODE_AUTH_TOKEN=your_github_token
```

### 2. 環境別のファイルを使用

環境ごとに異なる設定が必要な場合、環境別のファイルを作成できます：

```
remote/recurring-billing-form/
├── .env              # デフォルト（ローカル開発環境）
├── .env.dev          # 開発環境
├── .env.staging      # ステージング環境
└── .env.prod         # 本番環境
```

### 3. システム環境変数を使用

システム環境変数が設定されている場合、.envファイルよりも優先されます。

**優先順位:** システム環境変数 > アプリ固有の.env

---

## 必要な環境変数について

### ビルドに必須の環境変数

- `NODE_AUTH_TOKEN`: GitHub PackagesやプライベートNPMレジストリへのアクセストークン

### アプリケーション固有の環境変数

- `VITE_STRIPE_PUBLIC_KEY`: Stripe 公開用のAPIキー。Stripeダッシュボードから取得できます。
- `VITE_PAYMENT_ORIGIN`: Xium Payment PlatformのオリジンURL（例: `https://your-domain.com`）。

### スタンドアロンで必要な環境変数

- `VITE_ACCESS_TOKEN`: Xium IAMが発行したアクセストークン。検証用が用意されているので担当に確認してください。

---

## Dockerfile について

`Dockerfile`はマルチステージビルドを使用して、効率的なイメージを作成します：

1. **ビルダーステージ**: Node.js環境で依存関係のインストールとビルドを実行
2. **ランタイムステージ**: Nginxで静的ファイルを配信

**特徴:**
- アプリ名をビルド引数として受け取り、汎用的に使用可能
- pnpmワークスペースに対応
- レイヤーキャッシュを活用した高速ビルド
- 最終イメージサイズの最小化

---

## 横展開について

この`deploy`フォルダは他のMFEアプリにそのままコピーして使用できます：

```bash
# 例: plan-formへの展開
cp -r remote/recurring-billing-form/deploy remote/plan-form/
cp remote/recurring-billing-form/.dockerignore remote/plan-form/

# plan-formの.envを作成
cp remote/recurring-billing-form/.env remote/plan-form/.env
# 必要に応じて値を編集

# ビルド実行（アプリ名は自動検出）
bash remote/plan-form/deploy/docker_build_local.sh
```

スクリプトはディレクトリ構造からアプリ名を自動検出するため、コピー後は修正不要です。
