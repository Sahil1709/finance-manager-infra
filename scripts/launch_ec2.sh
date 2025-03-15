#!/bin/bash
set -e

# Launch an EC2 instance using a preconfigured AMI with Docker and docker-compose installed.
LAUNCH_OUTPUT=$(aws ec2 run-instances \
  --image-id ami-09c4c9ed89baac855 \
  --count 1 \
  --instance-type t3.medium \
  --key-name aws-academy-key \
  --security-group-ids sg-0a675cf6604c9961a \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=IntegrationTestInstance}]')

INSTANCE_ID=$(echo "$LAUNCH_OUTPUT" | jq -r '.Instances[0].InstanceId')
echo "Instance ID: $INSTANCE_ID"
echo "::set-output name=instance_id::$INSTANCE_ID"

# Wait until the instance is running.
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get the public IP of the instance.
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r '.Reservations[0].Instances[0].PublicIpAddress')
echo "Public IP: $PUBLIC_IP"
echo "::set-output name=public_ip::$PUBLIC_IP"
