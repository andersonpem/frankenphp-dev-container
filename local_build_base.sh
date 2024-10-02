#!/usr/bin/env bash
set -ex -o pipefail
# Base
# PHP 8.2
docker buildx build \
  --build-arg PHP_VERSION=8.2 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.2 \
  --file docker/Dockerfile \
  --push .

docker buildx build \
  --build-arg PHP_VERSION=8.3 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.2-php-8.3 \
  --file docker/Dockerfile \
  --push .

echo "All your cats are belong to us!"