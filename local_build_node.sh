#!/usr/bin/env bash
set -ex -o pipefail
# Node versions
# Node 18 php 8.2
docker buildx build \
  --build-arg NODE_VERSION=18 \
  --build-arg PHP_VERSION=8.2 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2-node-18\
  --file docker/Dockerfile-node \
  --push .

# Node 18 php 8.3
docker buildx build \
  --build-arg NODE_VERSION=18 \
  --build-arg PHP_VERSION=8.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2-node-18\
  --file docker/Dockerfile-node \
  --push .
######

# Node 20 php 8.2
docker buildx build \
  --build-arg NODE_VERSION=20 \
  --build-arg PHP_VERSION=8.2 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2-node-18\
  --file docker/Dockerfile-node \
  --push .

# Node 18 php 8.3
docker buildx build \
  --build-arg NODE_VERSION=20 \
  --build-arg PHP_VERSION=8.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2-node-18\
  --file docker/Dockerfile-node \
  --push .

#######

# Node 21 php 8.2
docker buildx build \
  --build-arg NODE_VERSION=21 \
  --build-arg PHP_VERSION=8.2 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2-node-18\
  --file docker/Dockerfile-node \
  --push .

# Node 18 php 8.3
docker buildx build \
  --build-arg NODE_VERSION=21 \
  --build-arg PHP_VERSION=8.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2-node-18\
  --file docker/Dockerfile-node \
  --push .

echo "All your cats are belong to us!"