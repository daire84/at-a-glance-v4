#!/bin/bash

# Make sure we're in the right directory
cd /mnt/user/appdata/film-scheduler-v4

# Check if the port is already in use
PORT_CHECK=$(netstat -tuln | grep ":5074" || true)
if [ ! -z "$PORT_CHECK" ]; then
  echo "WARNING: Port 5074 is already in use!"
  echo "Would you like to change the port? (y/n)"
  read change_port
  
  if [ "$change_port" = "y" ] || [ "$change_port" = "Y" ]; then
    echo "Please enter a new port number:"
    read new_port
    
    # Update the docker-compose.yml file
    sed -i "s/- \"5074:5000\"/- \"$new_port:5000\"/g" docker-compose.yml
    echo "Port updated to $new_port"
  else
    echo "Continuing with port 5074, but there may be conflicts..."
  fi
fi

# Create a backup of current data (if any)
if [ -d "data" ] && [ "$(ls -A data 2>/dev/null)" ]; then
  echo "Creating backup of existing data..."
  BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  cp -r data/* "$BACKUP_DIR/"
  echo "Backup created at $BACKUP_DIR"
fi

# Ensure directories exist
mkdir -p data/projects logs utils static/css static/js static/images templates/admin templates/components

# Start the containers
echo "Starting Film Production Scheduler..."
docker-compose up -d

# Check if the container is running
if [ "$(docker ps -q -f name=film-scheduler-v4)" ]; then
  echo "Film Production Scheduler is now running!"
  
  # Get the actual port from docker-compose.yml
  PORT=$(grep -oP '"\K\d+(?=:5000")' docker-compose.yml)
  
  echo "You can access it at:"
  echo "Local: http://localhost:$PORT"
  echo "Network: http://$(hostname -I | awk '{print $1}'):$PORT"
  echo "Cloudflare Tunnel: https://calendar.daireglynn.com (if configured)"
  
  echo "----------------------------------------"
  echo "To view logs: docker logs film-scheduler-v4"
  echo "To stop: ./stop.sh"
else
  echo "Failed to start Film Production Scheduler."
  echo "Check logs with: docker-compose logs"
fi
