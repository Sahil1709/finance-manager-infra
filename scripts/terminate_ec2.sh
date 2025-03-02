#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Instance ID not provided. Exiting."
  exit 1
fi

INSTANCE_ID=$1
echo "Terminating instance $INSTANCE_ID..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "Instance terminated."
