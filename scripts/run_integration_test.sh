#!/bin/bash
set -e

export ECR_REGISTRY=$ECR_REGISTRY
export FRONTEND_IMAGE="sahil1709/finance-manager-frontend"
export BACKEND_IMAGE="sahil1709/finance-manager-backend"

# Write AWS credentials to ~/.aws/credentials using env vars passed from the workflow.
mkdir -p ~/.aws
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
aws_session_token = ${AWS_SESSION_TOKEN}
EOF

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull latest images from ECR
echo "Pulling latest frontend image..."
docker pull ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
echo "Pulling latest backend image..."
docker pull ${ECR_REGISTRY}/${BACKEND_IMAGE}:latest

# Extract database password and database name from DATABASE_URL
DATABASE_PASSWORD=$(echo $DATABASE_URL | sed -n 's/.*:\/\/.*:\(.*\)@.*/\1/p')
DATABASE_NAME=$(echo $DATABASE_URL | sed -n 's/.*:\/\/.*\/\(.*\)/\1/p')

# Run containers using the updated images.
echo "Starting new containers..."
docker run -d --name frontend -p 3000:3000 ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
docker run -d --name backend -p 8000:8000 ${ECR_REGISTRY}/${BACKEND_IMAGE}:latest

# Start MySQL container with extracted database password and database name
# docker run --name mysql-8 -e MYSQL_ROOT_PASSWORD=$DATABASE_PASSWORD -e MYSQL_DATABASE=$DATABASE_NAME -d mysql:8

echo "Test Deployment complete!"

# Wait for containers to fully start.
sleep 30

# Run smoke tests.
FRONTEND_RESULT=$(curl -s http://localhost:3000/)
BACKEND_RESULT=$(curl -s http://localhost:8000/health/)

if echo "$FRONTEND_RESULT" | grep "Finance Manager" && echo "$BACKEND_RESULT" | grep healthy; then
  echo "SUCCESS" > /tmp/smoke_test_result.txt
  echo "::set-output name=result::success"
  docker compose down
  exit 0
else
  echo "FAILURE: Smoke tests did not pass." > /tmp/smoke_test_result.txt
  echo "::set-output name=result::failure"
  docker compose down
  exit 1
fi