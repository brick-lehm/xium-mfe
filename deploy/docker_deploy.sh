#!/bin/bash
set -e

# デフォルト値
APP_NAME=""
ENV_NAME=""

# コマンドライン引数を解析
while [[ $# -gt 0 ]]; do
  case $1 in
    -pj)
      APP_NAME="$2"
      shift 2
      ;;
    -env)
      ENV_NAME="$2"
      shift 2
      ;;
    *)
      echo "不明なオプション: $1"
      echo "使い方: $0 -pj <プロジェクト名> [-env <環境名>]"
      echo "例: $0 -pj plan-form -env prod  # .env.prod を読み込みます"
      exit 1
      ;;
  esac
done

# APP_NAMEが指定されているか確認
if [ -z "$APP_NAME" ]; then
  echo "エラー: -pj オプションでプロジェクト名を指定してください"
  echo "使い方: $0 -pj <プロジェクト名> [-env <環境名>]"
  echo "例: $0 -pj plan-form"
  exit 1
fi

# MFEディレクトリが存在するか確認
if [ ! -d "remote/${APP_NAME}" ]; then
  echo "エラー: remote/${APP_NAME} が存在しません"
  exit 1
fi

echo "MFEデプロイ開始: ${APP_NAME}"
if [ -n "$ENV_NAME" ]; then
  echo "環境: ${ENV_NAME}"
fi

# .envファイルから環境変数を読み込む関数
load_env_file() {
  local env_file="$1"
  if [ -f "$env_file" ]; then
    echo "環境変数を読み込み中: $env_file"
    # コメントと空行を除外し、環境変数として読み込む
    set -a
    source <(grep -v '^#' "$env_file" | grep -v '^$')
    set +a
  fi
}

# 優先順位: システム環境変数 > アプリ固有の.env[.環境名]
# アプリ固有の.envを読み込み（存在する場合）
if [ -n "$ENV_NAME" ]; then
  # 環境指定がある場合は .env.{環境名} を読み込む
  load_env_file "remote/${APP_NAME}/.env.${ENV_NAME}"
else
  # 環境指定がない場合は .env を読み込む
  load_env_file "remote/${APP_NAME}/.env"
fi

# 必須環境変数のチェック
if [ -z "${NODE_AUTH_TOKEN}" ]; then
  echo "エラー: NODE_AUTH_TOKEN が設定されていません"
  echo "   .envファイルまたはシステム環境変数に設定してください"
  exit 1
fi

# 環境変数の読み込み完了
echo "環境変数の読み込み完了"

# スクリプトのディレクトリからプロジェクトルートに移動
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

# 一時的に.dockerignoreをバックアップして、アプリ用のものに置き換え
if [ -f .dockerignore ]; then
  mv .dockerignore .dockerignore.backup
fi

# .dockerignoreが各MFEディレクトリにある場合はコピー
if [ -f "remote/${APP_NAME}/.dockerignore" ]; then
  cp "remote/${APP_NAME}/.dockerignore" .dockerignore
fi

# ビルド実行（エラーが起きても必ず.dockerignoreを戻す）
trap 'if [ -f .dockerignore.backup ]; then mv .dockerignore.backup .dockerignore; else rm -f .dockerignore; fi' EXIT

# --build-argを動的に構築（.envから読み込んだ変数を全て追加）
BUILD_ARGS="--build-arg APP_NAME=${APP_NAME}"

# .envファイルのパスを決定
if [ -n "$ENV_NAME" ]; then
  ENV_FILE="remote/${APP_NAME}/.env.${ENV_NAME}"
else
  ENV_FILE="remote/${APP_NAME}/.env"
fi

# .envファイルから読み込んだ変数をループで追加
if [ -f "$ENV_FILE" ]; then
  while IFS='=' read -r key value; do
    # コメント行と空行をスキップ
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    # クォートを削除
    value="${value%\"}"
    value="${value#\"}"

    # 変数参照（${VAR}形式）を展開
    # 既に環境変数として設定されている値があればそれを使用
    if [[ "$value" =~ ^\$\{([^}]+)\}$ ]]; then
      var_name="${BASH_REMATCH[1]}"  # ${VAR} から VAR を抽出
      value="${!var_name}"
    fi

    BUILD_ARGS="$BUILD_ARGS --build-arg ${key}=${value}"
  done < <(grep -v '^#' "$ENV_FILE" | grep -v '^$')
fi

echo ""
echo "🔨 Dockerビルドを開始します（マルチプラットフォーム）..."
echo ""
echo "ビルド引数:"
printf '%s\n' "$BUILD_ARGS"
echo ""

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "xiumjp/mfe-${APP_NAME}:latest" \
  $BUILD_ARGS \
  --no-cache \
  --push \
  -f "deploy/Dockerfile" \
  .

echo ""
echo "   デプロイが完了しました！"
echo "   イメージ: xiumjp/mfe-${APP_NAME}:latest"