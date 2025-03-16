#!/bin/bash
set -e

# Load environment variables from ../.env (if needed)
source ../.env

# Fetch the latest RC tag from the source repo.
# This queries the GitHub API for releases and filters for tags containing "rc".
RC_TAG=$(curl -s https://api.github.com/repos/Sahil1709/finance-manager/releases | jq -r 'map(select(.tag_name | test("rc"))) | .[0].tag_name')

if [ -z "$RC_TAG" ]; then
  echo "No RC tag found. Exiting."
  exit 1
fi

echo "Latest RC tag: ${RC_TAG}"

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull RC images using the RC tag from the source repo.
echo "Pulling RC frontend image..."
docker pull ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${RC_TAG}
echo "Pulling RC backend image..."
docker pull ${ECR_REGISTRY}/${BACKEND_IMAGE}:${RC_TAG}

# Stop and remove existing containers (if any)
echo "Stopping existing RC containers..."
docker rm -f frontend-rc || true
docker rm -f backend-rc || true

# Optionally, remove older images (if desired)
echo "Removing older frontend images..."
docker images ${ECR_REGISTRY}/${FRONTEND_IMAGE} --format "{{.ID}}" | tail -n +2 | xargs -r docker rmi
echo "Removing older backend images..."
docker images ${ECR_REGISTRY}/${BACKEND_IMAGE} --format "{{.ID}}" | tail -n +2 | xargs -r docker rmi

# Run containers using the RC images.
echo "Starting new RC containers..."
docker run -d --name frontend-rc -p 3000:3000 ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${RC_TAG}
docker run -d --name backend-rc -p 8000:8000 ${ECR_REGISTRY}/${BACKEND_IMAGE}:${RC_TAG}

echo "RC Deployment complete!"