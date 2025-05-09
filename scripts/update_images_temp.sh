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

# Stop and remove existing containers (if any)
echo "Stopping existing containers..."
docker rm -f frontend || true
docker rm -f backend || true

# Remove older images
echo "Removing older frontend images..."
docker images ${ECR_REGISTRY}/${FRONTEND_IMAGE} --format "{{.ID}}" | tail -n +2 | xargs -r docker rmi
echo "Removing older backend images..."
docker images ${ECR_REGISTRY}/${BACKEND_IMAGE} --format "{{.ID}}" | tail -n +2 | xargs -r docker rmi

# Run containers using the updated images.
echo "Starting new containers..."
docker run -d --name frontend -p 3000:3000 ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
docker run -d --name backend -p 8000:8000 ${ECR_REGISTRY}/${BACKEND_IMAGE}:latest

# start mysql
docker run --name mysql-8 -e MYSQL_ROOT_PASSWORD=$ -e MYSQL_DATABASE=$  -d mysql:8

echo "Test Deployment complete!"



# Wait for containers to fully start.
sleep 30

# Run smoke tests.
FRONTEND_RESULT=$(curl -s http://localhost:3000/)
BACKEND_RESULT=$(curl -s http://localhost:8000/health)

if echo "$FRONTEND_RESULT" | grep -qi "Finance Manager" && echo "$BACKEND_RESULT" | grep -qi "\"status\": \"healthy\""; then
  echo "SUCCESS" > /tmp/smoke_test_result.txt
else
  echo "FAILURE: Smoke tests did not pass." > /tmp/smoke_test_result.txt
  docker-compose down
  exit 1
fi
