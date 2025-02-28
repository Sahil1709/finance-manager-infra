#!/bin/bash
set -e
source ../.env

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull latest images from ECR
echo "Pulling latest frontend image..."
docker pull ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
echo "Pulling latest backend image..."
docker pull ${ECR_REGISTRY}/${BACKEND_IMAGE}:latest

# Stop and remove existing containers (if any)
echo "Stopping existing containers..."
docker rm -f frontend || true
docker rm -f backend || true

# Run containers using the updated images.
echo "Starting new containers..."
docker run -d --name frontend -p 3000:3000 ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
docker run -d --name backend -p 8000:8000 ${ECR_REGISTRY}/${BACKEND_IMAGE}:latest

echo "Deployment complete!"
