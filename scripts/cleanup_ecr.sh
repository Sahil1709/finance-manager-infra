#!/bin/bash
set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Both frontend and backend tags must be provided. Exiting."
  exit 1
fi

FRONTEND_TAG=$1
BACKEND_TAG=$2

echo "Cleaning up ECR images with tags: Frontend=$FRONTEND_TAG, Backend=$BACKEND_TAG"

aws ecr batch-delete-image --repository-name finance-manager-frontend --image-ids imageTag=$FRONTEND_TAG
aws ecr batch-delete-image --repository-name finance-manager-backend --image-ids imageTag=$BACKEND_TAG

echo "Cleanup complete."
