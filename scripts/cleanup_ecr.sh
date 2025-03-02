#!/bin/bash
set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Both frontend and backend tags must be provided. Exiting."
  exit 1
fi

FRONTEND_REPO=$1
BACKEND_REPO=$2
FRONTEND_TAG=$3
BACKEND_TAG=$4

echo "Cleaning up ECR images with tags: Frontend=$FRONTEND_TAG, Backend=$BACKEND_TAG"

aws ecr batch-delete-image --repository-name $FRONTEND_REPO --image-ids imageTag=$FRONTEND_TAG
aws ecr batch-delete-image --repository-name $BACKEND_REPO --image-ids imageTag=$BACKEND_TAG

echo "Cleanup complete."
