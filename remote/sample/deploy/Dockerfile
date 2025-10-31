# ステージ：１
# リモートビルドを行うためのステージです。
FROM node:20-alpine AS builder

# ビルド引数でアプリ名を受け取る（デフォルトは"app"）
ARG APP_NAME=app

# プロビジョニング
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /workspace

# 依存関係のインストールに必要なファイルのみを先にコピー（キャッシュ活用）
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml .npmrc ./
COPY remote/${APP_NAME}/package.json ./remote/app/

# package.jsonの名前を"app"に変更してpnpmワークスペースで認識させる
RUN sed -i 's/"name": "[^"]*"/"name": "app"/' ./remote/app/package.json

# 依存性のインストール
# ここでNODE_AUTH_TOKENを使用してプライベートパッケージのインストールを行います。
ARG NODE_AUTH_TOKEN
ENV NODE_AUTH_TOKEN=${NODE_AUTH_TOKEN}
RUN pnpm install --filter app... && \
    pnpm store prune && \
    rm -f .npmrc

# ソースコードをコピー
COPY remote/${APP_NAME} ./remote/app

# ビルド
WORKDIR /workspace/remote/app
RUN pnpm run build

# ステージ：２
# nginxのフォワードを使用した外部公開を行うステージです。
FROM nginx:alpine

# ビルド引数を再度宣言してこのステージでも使えるようにする
ARG APP_NAME=app

# nginxの設定をコピー（appディレクトリから）
COPY --from=builder /workspace/remote/app/deploy/nginx.conf /etc/nginx/conf.d/default.conf

# アプリケーションのビルド成果物をnginxの公開ディレクトリにコピー
# APP_NAMEを使用して動的にパスを設定
COPY --from=builder /workspace/remote/app/dist /usr/share/nginx/html/${APP_NAME}
COPY --from=builder /workspace/remote/app/package.json /usr/share/nginx/html/${APP_NAME}/package.json
COPY --from=builder /workspace/pnpm-lock.yaml /usr/share/nginx/html/${APP_NAME}/pnpm-lock.yaml

# エントリーポイントスクリプトを追加
COPY --from=builder /workspace/remote/app/deploy/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 環境変数として設定
ENV APP_NAME=${APP_NAME}

# ヘルスチェックの設定（環境変数は実行時に展開されるため、シェル形式を使用）
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/${APP_NAME}/assets/remoteEntry.js || exit 1

# Expose port
EXPOSE 80

# Use custom entrypoint to inject runtime config
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
