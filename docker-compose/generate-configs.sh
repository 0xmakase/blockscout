#!/bin/bash

CHAIN_ID=$1
CHAIN_NAME=$2
DOMAIN_NAME=$3
RPC_URL=$4
WALLET_PROJECT_ID=$5

# RPC_URLからホスト名と末尾のポート番号を抽出し、ポート番号を+1する
HOST=$(echo "$RPC_URL" | sed -E 's|https?://([^:/]+).*|\1|')
PORT=$(echo "$RPC_URL" | grep -oE ':[0-9]+/?$' | grep -oE '[0-9]+')

# ポート番号が指定されていない場合はデフォルトで80に設定
if [ -z "$PORT" ]; then
  PORT=80
fi

# ポート番号をインクリメント
WS_PORT=$((PORT + 1))

# インクリメントされたポート番号を使用してWS_URLを構築
if [[ "$RPC_URL" == http* ]]; then
  WS_URL="ws://$HOST:$WS_PORT"
else
  WS_URL="$RPC_URL"
fi

UPPER_CHAIN_NAME=$(echo "$CHAIN_NAME" | tr 'a-z' 'A-Z')

DOCKER_COMPOSE_FILE="docker-compose.yml"
COMMON_BLOCKSCOUT_ENV_FILE="envs/common-blockscout.env"
COMMON_FRONTEND_ENV_FILE="envs/common-frontend.env"
USER_OPS_INDEXER_FILE="services/user-ops-indexer.yml"
DEFAULT_CONF_TEMPLATE_FILE="proxy/default.conf.template"

# Replace placeholders in the docker-compose.yml
sed -i "s|{{RPC_URL}}|$RPC_URL|g" "$DOCKER_COMPOSE_FILE"
sed -i "s|{{RPC_WS_URL}}|$WS_URL|g" "$DOCKER_COMPOSE_FILE"
sed -i "s|{{CHAIN_ID}}|$CHAIN_ID|g" "$DOCKER_COMPOSE_FILE"

# Replace placeholders in the common-blockscout.env
sed -i "s|{{RPC_URL}}|$RPC_URL|g" "$COMMON_BLOCKSCOUT_ENV_FILE"

# Replace placeholders in the common-frontend.env
sed -i "s|{{CURRENCY_NAME}}|$CHAIN_NAME|g" "$COMMON_FRONTEND_ENV_FILE"
sed -i "s|{{CURRENCY_SYMBOL}}|$UPPER_CHAIN_NAME|g" "$COMMON_FRONTEND_ENV_FILE"
sed -i "s|{{DOMAIN_NAME}}|$DOMAIN_NAME|g" "$COMMON_FRONTEND_ENV_FILE"
sed -i "s|{{CHAIN_ID}}|$CHAIN_ID|g" "$COMMON_FRONTEND_ENV_FILE"
sed -i "s|{{RPC_URL}}|$RPC_URL|g" "$COMMON_FRONTEND_ENV_FILE"
sed -i "s|{{WALLET_PROJECT_ID}}|$WALLET_PROJECT_ID|g" "$COMMON_FRONTEND_ENV_FILE"

# Replace placeholders in the user-ops-indexer.yml
sed -i "s|{{RPC_WS_URL}}|$WS_URL|g" "$USER_OPS_INDEXER_FILE"

# Replace placeholders in the default.conf.template
sed -i "s|{{DOMAIN_NAME}}|$DOMAIN_NAME|g" "$DEFAULT_CONF_TEMPLATE_FILE"

echo "Configuration files generated for $CHAIN_NAME"
