#!/bin/bash

CHAIN_ID=$1
CHAIN_NAME=$2
RPC_URL=$3
WS_URL=${RPC_URL/http/ws}
UPPER_CHAIN_NAME=$(echo "$CHAIN_NAME" | tr 'a-z' 'A-Z')

DOCKER_COMPOSE_FILE="docker-compose.yml"
COMMON_BLOCKSCOUT_ENV_FILE="envs/common-blockscout.env"
COMMON_FRONTEND_ENV_FILE="envs/common-frontend.env"
USER_OPS_INDEXER_FILE="user-ops-indexer.yml"

# Replace placeholders in the docker-compose.yml
sed -i "s|{{RPC_URL}}|$RPC_URL|g" $DOCKER_COMPOSE_FILE
sed -i "s|{{RPC_WS_URL}}|$WS_URL|g" $DOCKER_COMPOSE_FILE

# Replace placeholders in the common-blockscout.env
sed -i "s|{{RPC_URL}}|$RPC_URL|g" $COMMON_BLOCKSCOUT_ENV_FILE

# Replace placeholders in the common-frontend.env
sed -i "s|{{CURRENCY_NAME}}|$CHAIN_NAME|g" $COMMON_FRONTEND_ENV_FILE
sed -i "s|{{CURRENCY_SYMBOL}}|$UPPER_CHAIN_NAME|g" $COMMON_FRONTEND_ENV_FILE

# Replace placeholders in the user-ops-indexer.yml
sed -i "s|{{RPC_WS_URL}}|$WS_URL|g" $USER_OPS_INDEXER_FILE

echo "Configuration files generated for $CHAIN_NAME"
