#!/bin/bash
# Updated script to fix the SVG conversion issue

# 1. Update the Dockerfile to include the required librsvg2-bin package
cat > /mnt/user/appdata/film-scheduler-v4/Dockerfile << 'EOF'
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production \
    FLASK_APP=app.py

# Set working directory and create necessary directories
WORKDIR /app

# Install dependencies first (better layer caching)
COPY requirements.txt .
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir -r requirements.txt gunicorn

# Create data and logs directories with correct permissions
RUN mkdir -p data/projects logs static
RUN chmod -R 755 data logs

# Copy application files
COPY . .

# Install ImageMagick and librsvg2-bin for favicon conversion
RUN apt-get update && \
    apt-get install -y --no-install-recommends imagemagick librsvg2-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose port
EXPOSE 5000

# Default command (will be overridden by docker-compose command)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "2", "--access-logfile", "/app/logs/access.log", "--error-logfile", "/app/logs/error.log", "app:app"]
