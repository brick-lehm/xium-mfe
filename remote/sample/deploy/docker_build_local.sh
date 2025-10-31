#!/bin/bash
set -e

# スクリプトのディレクトリからアプリ名を自動検出
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="$(basename "$(dirname "$SCRIPT_DIR")")"

# デフォルトの環境名
ENV_NAME=""

# コマンドライン引数を解析
while [[ $# -gt 0 ]]; do
  case $1 in
    -env)
      ENV_NAME="$2"
      shift 2
      ;;
    *)
      echo "不明なオプション: $1"
      echo "使い方: $0 [-env <環境名>]"
      echo "例: $0 -env prod  # .env.prod を読み込みます"
      exit 1
      ;;
  esac
done

echo "MFEビルド開始: ${APP_NAME}"
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
  load_env_file "$(dirname "$SCRIPT_DIR")/.env.${ENV_NAME}"
else
  # 環境指定がない場合は .env を読み込む
  load_env_file "$(dirname "$SCRIPT_DIR")/.env"
fi

# プロジェクトルートに移動
cd "$(dirname "$0")/../../.."

# 一時的に.dockerignoreをバックアップして、アプリ用のものに置き換え
if [ -f .dockerignore ]; then
  mv .dockerignore .dockerignore.backup
fi
cp "remote/${APP_NAME}/.dockerignore" .dockerignore

# ビルド実行（エラーが起きても必ず.dockerignoreを戻す）
trap 'if [ -f .dockerignore.backup ]; then mv .dockerignore.backup .dockerignore; else rm -f .dockerignore; fi' EXIT

# --build-argを動的に構築（.envから読み込んだ変数を全て追加）
BUILD_ARGS="--build-arg APP_NAME=${APP_NAME}"

# .envファイルのパスを決定
if [ -n "$ENV_NAME" ]; then
  ENV_FILE="$(dirname "$SCRIPT_DIR")/.env.${ENV_NAME}"
else
  ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
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
echo "🔨 Dockerビルドを開始します..."

docker build \
  -t "mfe-${APP_NAME}:local" \
  $BUILD_ARGS \
  -f "remote/${APP_NAME}/deploy/Dockerfile" \
  .

echo ""
echo "ビルドが完了しました！"
echo ""
echo "コンテナを起動するには:"
echo "  docker run -d -p 8080:80 --name ${APP_NAME}-test mfe-${APP_NAME}:local"
echo ""
echo "起動後にアクセス:"
echo "  http://localhost:8080/${APP_NAME}/assets/remoteEntry.js"
echo "  http://localhost:8080/${APP_NAME}/"
echo ""
echo "コンテナを停止・削除するには:"
echo "  docker stop ${APP_NAME}-test && docker rm ${APP_NAME}-test"
