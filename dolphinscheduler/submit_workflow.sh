#!/bin/bash

DOLPHINSCHEDULER_API="http://localhost:12345/dolphinscheduler"
USERNAME="admin"
PASSWORD="dolphinscheduler123"

echo "=== Submitting DolphinScheduler workflow ==="

# Get token
echo "Authenticating..."
TOKEN=$(curl -s -X POST "$DOLPHINSCHEDULER_API/login" \
    -H "Content-Type: application/json" \
    -d "{\"userName\":\"$USERNAME\",\"userPassword\":\"$PASSWORD\"}" | jq -r '.data.token')

echo "Token obtained"

# Create project
echo "Creating project..."
curl -s -X POST "$DOLPHINSCHEDULER_API/projects" \
    -H "Content-Type: application/json" \
    -H "token: $TOKEN" \
    -d '{"name":"gmall","description":"电商数仓项目"}'

# Upload workflow
echo "Uploading workflow..."
curl -s -X POST "$DOLPHINSCHEDULER_API/workflow/import" \
    -H "Content-Type: multipart/form-data" \
    -H "token: $TOKEN" \
    -F "file=@/mnt/d/s/作业/dolphinscheduler/workflow.json" \
    -F "projectName=gmall"

echo "=== Workflow submitted successfully ==="