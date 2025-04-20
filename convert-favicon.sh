#!/bin/bash
set -e  # Exit on any error

echo "Starting favicon conversion..."
cd /app/static/images

# Check if favicon.svg exists
if [ ! -f favicon.svg ]; then
  echo "Error: favicon.svg not found!"
  exit 1
fi

# Create PNG versions
echo "Converting SVG to 16x16 PNG..."
convert favicon.svg -background none -resize 16x16 favicon-16.png
echo "Converting SVG to 32x32 PNG..."
convert favicon.svg -background none -resize 32x32 favicon-32.png
echo "Converting SVG to 48x48 PNG..."
convert favicon.svg -background none -resize 48x48 favicon-48.png

# Check if PNGs were created
if [ ! -f favicon-16.png ] || [ ! -f favicon-32.png ] || [ ! -f favicon-48.png ]; then
  echo "Error: Failed to create PNG files!"
  ls -la
  exit 1
fi

# Create ICO file
echo "Creating ICO file from PNGs..."
convert favicon-16.png favicon-32.png favicon-48.png favicon.ico

echo "Favicon conversion complete!"
