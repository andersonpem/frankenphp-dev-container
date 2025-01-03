#!/usr/bin/env bash
set -ex -o pipefail
# Base
# PHP 8.2
docker buildx build \
  --build-arg PHP_VERSION=8.2 \
  --build-arg FRANKENPHP_VERSION=1.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.3-php-8.2 \
  --file docker/Dockerfile \
  --push .

# PHP 8.3
docker buildx build \
  --build-arg PHP_VERSION=8.3 \
  --build-arg FRANKENPHP_VERSION=1.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.3-php-8.3 \
  --file docker/Dockerfile \
  --push .

# PHP 8.4
docker buildx build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg FRANKENPHP_VERSION=1.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.3-php-8.4 \
  --file docker/Dockerfile \
  --push .

echo "All your cats are belong to us!"