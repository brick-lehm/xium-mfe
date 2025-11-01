#!/bin/sh
set -e

# APP_NAMEが設定されていない場合はデフォルト値を使用
APP_NAME=${APP_NAME:-app}

echo "Configuring nginx for app: $APP_NAME"

# nginx設定ファイルのテンプレート変数を置換
sed -i "s/\${APP_NAME}/$APP_NAME/g" /etc/nginx/conf.d/default.conf

# 設定ファイルの内容を確認（デバッグ用）
echo "Generated nginx configuration:"
cat /etc/nginx/conf.d/default.conf

# nginx設定ファイルの構文チェック
nginx -t

# nginx を起動
exec "$@"