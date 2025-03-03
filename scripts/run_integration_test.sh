#!/bin/bash
set -e

export DATABASE_URL=$DATABASE_URL
export FRONTEND_URL=$FRONTEND_URL
export MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
export MYSQL_DATABASE=$MYSQL_DATABASE
export NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
export CLERK_SECRET_KEY=$CLERK_SECRET_KEY
export NEXT_PUBLIC_BACKEND_URL=$NEXT_PUBLIC_BACKEND_URL


cd finance-manager
git pull

cd backend
echo "Creating .env file for backend"
cat <<EOF > .env
DATABASE_URL=$DATABASE_URL
FRONTEND_URL=$FRONTEND_URL
EOF

cat .env

cd ../frontend
echo "Creating .env.local file for frontend"
cat <<EOF > .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY=$CLERK_SECRET_KEY
NEXT_PUBLIC_BACKEND_URL=$NEXT_PUBLIC_BACKEND_URL
EOF

cat .env.local

cd ..
docker compose up -d --build

echo "Test Deployment complete!"

# Wait for containers to fully start.
sleep 10

# Check if containers are running.
docker ps -a

if ! docker ps | grep frontend && ! docker ps | grep backend; then
  echo "Containers are not running."
  exit 2
fi

echo "Testing database connection..."
mysql -h "${DATABASE_URL}" -u root -p"${DATABASE_PASSWORD}" -e "USE ${DATABASE_NAME}; SELECT 1;" || {
    echo "Database connection failed"
    exit 3
}

# Run smoke tests.
FRONTEND_RESULT=$(curl -s http://localhost:3000/)
BACKEND_RESULT=$(curl -s http://localhost:8000/health/)

if echo "$FRONTEND_RESULT" | grep "Finance Manager" && echo "$BACKEND_RESULT" | grep healthy; then
  echo "SUCCESS: Smoke tests passed."
  echo "SUCCESS" > /tmp/smoke_test_result.txt
  echo "::set-output name=result::success"
  docker compose down
else
  echo "FAILURE: Smoke tests did not pass."
  echo "FAILURE: Smoke tests did not pass." > /tmp/smoke_test_result.txt
  echo "::set-output name=result::failure"
  docker compose down
fi