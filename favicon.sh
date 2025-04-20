#!/bin/bash
# Steps to implement favicon in your Film Production Scheduler v4

# 1. First, save the SVG file you prefer to your project
mkdir -p /mnt/user/appdata/film-scheduler-v4/static/images
cat > /mnt/user/appdata/film-scheduler-v4/static/images/favicon.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <!-- Background -->
  <rect x="4" y="4" width="56" height="56" rx="8" fill="#546e7a" />
  
  <!-- Calendar Page -->
  <rect x="12" y="12" width="40" height="40" rx="2" fill="#ffffff" />
  
  <!-- Calendar Header Bar -->
  <rect x="12" y="12" width="40" height="8" rx="1" fill="#5d89ba" />
  
  <!-- Calendar Lines -->
  <line x1="12" y1="28" x2="52" y2="28" stroke="#e0e2e7" stroke-width="1" />
  <line x1="12" y1="36" x2="52" y2="36" stroke="#e0e2e7" stroke-width="1" />
  <line x1="12" y1="44" x2="52" y2="44" stroke="#e0e2e7" stroke-width="1" />
  
  <!-- Calendar Vertical Dividers -->
  <line x1="22" y1="20" x2="22" y2="52" stroke="#e0e2e7" stroke-width="1" />
  <line x1="32" y1="20" x2="32" y2="52" stroke="#e0e2e7" stroke-width="1" />
  <line x1="42" y1="20" x2="42" y2="52" stroke="#e0e2e7" stroke-width="1" />
  
  <!-- Film Slate Element -->
  <rect x="16" y="22" width="12" height="4" rx="1" fill="#ffd8e6" />
  <rect x="36" y="30" width="12" height="4" rx="1" fill="#e6ffd8" />
  <rect x="24" y="38" width="12" height="4" rx="1" fill="#d4e9ff" />
  
  <!-- Clapperboard Top Bar -->
  <rect x="36" y="16" width="12" height="2" rx="1" fill="#2d3142" />
  <path d="M36,16 L48,18 L48,16 Z" fill="#2d3142" />
</svg>
EOF

# 2. Convert SVG to ICO format using ImageMagick
# Note: You'll need to install ImageMagick in your Docker container or host
# Add these to your Dockerfile if using Docker:
# RUN apt-get update && apt-get install -y imagemagick

# Create the ICO file with multiple sizes (16x16, 32x32, 48x48)
cat > /mnt/user/appdata/film-scheduler-v4/convert-favicon.sh << 'EOF'
#!/bin/bash
cd /app/static/images
convert favicon.svg -background none -resize 16x16 favicon-16.png
convert favicon.svg -background none -resize 32x32 favicon-32.png
convert favicon.svg -background none -resize 48x48 favicon-48.png
convert favicon-16.png favicon-32.png favicon-48.png favicon.ico
EOF

# Make the script executable
chmod +x /mnt/user/appdata/film-scheduler-v4/convert-favicon.sh

# 3. Update your base.html template to include the favicon
# Edit the head section of your base.html file
cat > /mnt/user/appdata/film-scheduler-v4/templates/base.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Your Schedule, At a Glance!{% endblock %}</title>
    
    <!-- Favicon links -->
    <link rel="icon" type="image/svg+xml" href="/static/images/favicon.svg">
    <link rel="icon" type="image/png" sizes="32x32" href="/static/images/favicon-32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/static/images/favicon-16.png">
    <link rel="shortcut icon" href="/static/images/favicon.ico">
    
    <link rel="stylesheet" href="/static/css/style.css">
    {% block styles %}{% endblock %}
    <style>
        /* Navigation styles */
        .main-header {
            position: relative;
        }
        
        .main-nav {
            display: flex;
            justify-content: flex-end;
        }
        
        /* ... rest of your existing CSS ... */
    </style>
</head>
<body>
    <!-- ... rest of your existing HTML ... -->
</body>
</html>
EOF

# 4. Modify your Dockerfile to ensure ImageMagick is installed
# Add these lines to your Dockerfile
cat >> /mnt/user/appdata/film-scheduler-v4/Dockerfile << 'EOF'

# Install ImageMagick for favicon conversion
RUN apt-get update && \
    apt-get install -y --no-install-recommends imagemagick && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Run the favicon conversion script during build
COPY convert-favicon.sh /app/
RUN chmod +x /app/convert-favicon.sh && /app/convert-favicon.sh
EOF

# 5. Rebuild your Docker container
cd /mnt/user/appdata/film-scheduler-v4
docker-compose down
docker-compose build
docker-compose up -d

echo "Favicon implementation complete!"
