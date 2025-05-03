#!/bin/bash
set +e  # don’t bail on first failure

# HOST must be set in the environment
echo "Frontend ELB: http://$HOST/"

# 1) Wait for frontend to be healthy (up to 10 tries)
FRONTEND_STATUS=0
for i in $(seq 1 10); do
    FRONTEND_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://"$HOST"/)
    echo "Attempt $i: Frontend HTTP $FRONTEND_STATUS"
    [ "$FRONTEND_STATUS" -eq 200 ] && break
    sleep 10
done

if [ "$FRONTEND_STATUS" -ne 200 ]; then
    echo "❌ Frontend never came up (last HTTP $FRONTEND_STATUS)"
    FRONTEND_RESULT=""
else
    FRONTEND_RESULT=$(curl -s http://"$HOST"/)
fi
echo "Frontend result: $FRONTEND_RESULT"

# 2) Wait/single-check backend
BACKEND_RESULT=$(curl -s http://localhost:8000/health/)
echo "Backend result: $BACKEND_RESULT"

# 3) Wait/single-check analytics
ANALYTICS_RESULT=$(curl -s "http://localhost:8001/analytics-api/insights/userid/?userid=1234")
echo "Analytics result: $ANALYTICS_RESULT"

# 4) Evaluate
PASS=true

if [[ "$FRONTEND_RESULT" != *"Finance Manager"* ]]; then
    echo "❌ Frontend content check failed."
    PASS=false
else
    echo "✅ Frontend content OK."
fi

if [[ "$BACKEND_RESULT" != *"healthy"* ]]; then
    echo "❌ Backend health check failed."
    PASS=false
else
    echo "✅ Backend healthy."
fi

if [[ "$ANALYTICS_RESULT" != *"No transactions"* ]]; then
    echo "❌ Analytics check failed."
    PASS=false
else
    echo "✅ Analytics “No transactions” OK."
fi

if [ "$PASS" = true ]; then
    echo "🎉 UAT tests passed."
    echo "result=success" >> $GITHUB_OUTPUT
else
    echo "🚨 UAT tests did not pass."
    echo "result=failure" >> $GITHUB_OUTPUT
    exit 1
fi
