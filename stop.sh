#!/bin/bash

# Make sure we're in the right directory
cd /mnt/user/appdata/film-scheduler-v4

# Stop the containers
echo "Stopping Film Production Scheduler..."
docker-compose down

# Check if containers are stopped
if [ -z "$(docker ps -q -f name=film-scheduler-v4)" ]; then
  echo "Film Production Scheduler has been stopped."
else
  echo "Warning: There was an issue stopping the containers."
  echo "Try manually with: docker stop film-scheduler-v4"
fi
