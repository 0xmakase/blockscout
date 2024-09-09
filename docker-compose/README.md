# Docker-compose configuration

Runs Blockscout locally in Docker containers with [docker-compose](https://github.com/docker/compose).

## Prerequisites

- Docker v20.10+
- Docker-compose 2.x.x+
- Running Ethereum JSON RPC client

## Building Docker containers from source

**Note**: in all below examples, you can use `docker compose` instead of `docker-compose`, if compose v2 plugin is installed in Docker.

```bash
cd ./docker-compose
docker-compose up --build
```

**Note**: if you don't need to make backend customizations, you can run `docker-compose up` in order to launch from pre-build backend Docker image. This will be much faster.

This command uses `docker-compose.yml` by-default, which builds the backend of the explorer into the Docker image and runs 9 Docker containers:

- Postgres 14.x database, which will be available at port 7432 on the host machine.
- Redis database of the latest version.
- Blockscout backend with api at /api path.
- Nginx proxy to bind backend, frontend and microservices.
- Blockscout explorer at http://localhost.

and 5 containers for microservices (written in Rust):

- [Stats](https://github.com/blockscout/blockscout-rs/tree/main/stats) service with a separate Postgres 14 DB.
- [Sol2UML visualizer](https://github.com/blockscout/blockscout-rs/tree/main/visualizer) service.
- [Sig-provider](https://github.com/blockscout/blockscout-rs/tree/main/sig-provider) service.
- [User-ops-indexer](https://github.com/blockscout/blockscout-rs/tree/main/user-ops-indexer) service.

**Note for Linux users**: Linux users need to run the local node on http://0.0.0.0/ rather than http://127.0.0.1/

## Configs for different Ethereum clients

The repo contains built-in configs for different JSON RPC clients without need to build the image.

| __JSON RPC Client__    | __Docker compose launch command__ |
| -------- | ------- |
| Erigon  | `docker-compose -f erigon.yml up -d`    |
| Geth (suitable for Reth as well) | `docker-compose -f geth.yml up -d`     |
| Geth Clique    | `docker-compose -f geth-clique-consensus.yml up -d`    |
| Nethermind, OpenEthereum    | `docker-compose -f nethermind up -d`    |
| Ganache    | `docker-compose -f ganache.yml up -d`    |
| HardHat network    | `docker-compose -f hardhat-network.yml up -d`    |

- Running only explorer without DB: `docker-compose -f external-db.yml up -d`. In this case, no db container is created. And it assumes that the DB credentials are provided through `DATABASE_URL` environment variable on the backend container.
- Running explorer with external backend: `docker-compose -f external-backend.yml up -d`
- Running explorer with external frontend: `docker-compose -f external-frontend.yml up -d`
- Running all microservices: `docker-compose -f microservices.yml up -d`

All of the configs assume the Ethereum JSON RPC is running at http://localhost:8545.

In order to stop launched containers, run `docker-compose -d -f config_file.yml down`, replacing `config_file.yml` with the file name of the config which was previously launched.

You can adjust BlockScout environment variables:

- for backend in `./envs/common-blockscout.env`
- for frontend in `./envs/common-frontend.env`
- for stats service in `./envs/common-stats.env`
- for visualizer in `./envs/common-visualizer.env`
- for user-ops-indexer in `./envs/common-user-ops-indexer.env`

Descriptions of the ENVs are available

- for [backend](https://docs.blockscout.com/for-developers/information-and-settings/env-variables)
- for [frontend](https://github.com/blockscout/frontend/blob/main/docs/ENVS.md).

## Running Docker containers via Makefile

Prerequisites are the same, as for docker-compose setup.

Start all containers:

```bash
cd ./docker
make start
```

Stop all containers:

```bash
cd ./docker
make stop
```

***Note***: Makefile uses the same .env files since it is running docker-compose services inside.

## Configuration Script for Blockchain Services

This script is designed to configure various files for blockchain services by replacing placeholders with actual values provided as script arguments. The script accepts the following arguments:

1. `CHAIN_ID` - The ID of the blockchain chain.
2. `CHAIN_NAME` - The name of the blockchain chain.
3. `DOMAIN_NAME` - The domain of the blockchain chain.
4. `RPC_URL` - The RPC URL for the blockchain chain.
5. `WALLET_PROJECT_ID` - Set WalletConnect project ID.

The script will automatically generate the corresponding WebSocket URL (`WS_URL`) by replacing `http` with `ws` in the provided `RPC_URL`, and it will also convert the `CHAIN_NAME` to uppercase (`UPPER_CHAIN_NAME`).

### Usage

Run the script with the following command:

```bash
./generate-configs.sh <CHAIN_ID> <CHAIN_NAME> <DOMAIN_NAME> <RPC_URL> <WALLET_PROJECT_ID>
```
### Example
```bash
./generate-configs.sh 1 ethereum explorer.domain.eth https://mainnet.infura.io abbbbbbbd454320f12345f18e3a9abec
```
```bash
./generate-configs.sh 80085 bera beratest.0xmakase.co.jp https://bera-rpc.0xmakase.co.jp:8745/ abbbbbbbd454320f12345f18e3a9abec
```


### Script Details

```bash
#!/bin/bash

CHAIN_ID=$1
CHAIN_NAME=$2
DOMAIN_NAME=$3
RPC_URL=$4
WALLET_PROJECT_ID=$5
WS_URL=${RPC_URL/http/ws}
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
```
### File Descriptions

- docker-compose.yml: The configuration file for Docker Compose, where the {{RPC_URL}} and {{RPC_WS_URL}} placeholders will be replaced.
- envs/common-blockscout.env: The environment configuration file for Blockscout, where the {{RPC_URL}} placeholder will be replaced.
- envs/common-frontend.env: The environment configuration file for the frontend, where the {{CURRENCY_NAME}} and {{CURRENCY_SYMBOL}} placeholders will be replaced.
- services/user-ops-indexer.yml: The configuration file for the user operations indexer, where the {{RPC_WS_URL}} placeholder will be replaced.

### Notes
- Ensure that the script has executable permissions. You can set this with the following command:
```bash
chmod +x generate-configs.sh
```
- The script should be run from the directory containing the configuration files or should include the correct paths to those files.

By using this script, you can easily configure your blockchain services with the correct RPC and WebSocket URLs and other chain-specific details.