#!/usr/bin/env bash
set -ex -o pipefail

# Attempt docker login to GitHub Container Registry
if ! docker login; then
  echo "Docker login to docker hub failed."
  exit 1
fi


# PHP 8.4
docker buildx build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg FRANKENPHP_VERSION=1.9 \
  --platform linux/amd64,linux/arm64 \
  --tag phillarmonic/frankenphp-workspace:1.12-php-8.4 \
  --file docker/Dockerfile \
  --push .

echo "All your cats are belong to us!"
