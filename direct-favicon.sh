#!/bin/bash
# Direct favicon generation on the Unraid host

# 1. Create favicon directory if it doesn't exist
mkdir -p /mnt/user/appdata/film-scheduler-v4/static/images

# 2. Save the SVG file directly
cat > /mnt/user/appdata/film-scheduler-v4/static/images/favicon.svg << 'SVGEND'
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
SVGEND

echo "SVG favicon created at /mnt/user/appdata/film-scheduler-v4/static/images/favicon.svg"

# 3. Create placeholder PNG and ICO files (these will be simple colored squares)
# Creates a 16x16 red square PNG
cat > /mnt/user/appdata/film-scheduler-v4/static/images/favicon-16.png << 'PNGEND'
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAnElEQVQ4y2P4//8/w38GKKC9gSlj/7m8pBP3JnTc
e8BQdOIRQ9bxpwxZxx7D8Z0HTKUnH40CqmME6WUEacTQcffBA4a8Y0/BOjKPP0GRK7v3cqbW2n1eQM1YDQAZkHfi
KRgXnnjMANKcc+zx/9yjD/9nnbi/Caw568TjWIbMkw+XAQ3BbgDIgMxjj+AYbkjGiQcMLCxAl/5/MA+knxEAWPtu
aZDIfGkAAAAASUVORK5CYII=
PNGEND
echo "Created placeholder 16x16 PNG favicon"

# Create 32x32 placeholder
cat > /mnt/user/appdata/film-scheduler-v4/static/images/favicon-32.png << 'PNGEND'
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABPUlEQVRYw+2XwWrCQBCG/0nU+hBCwIs3L+LVHjyJ
By+CeO/7P0XBkyAIXgWP3hQEFVrB0Nhl/WcyEGONtNBLoYHAZmc385GZ3dldIeHEnNJ4fv0C0J8y+f6mD+DJFODo
tGJ6wDMA7YkTawDrKROXALoTSawAtCdc+BYAXQD9GZJrAPOJk6Nra+LkdwA+JtpbHF07vLe24twAliGCRQBGb4h3
AGsToqVVIVoCqA8RVm3rSLfitDp2IM83pNYAVgHu94VoCWA54sO0sKk47aJ7AIshwsK2jlwmtDp2INcVp9UAFgHE
QYh7Ie6E+Aji5TFEoAKYj/iw2XAuQKED2N4JkesAtgHiIMQ8iM9Ar9/fS5S1lKgQXwMQByEuXaKjQkw9IQK9hsjl
TZEN8TmdB5lfyWQT0s6Xcv5TSuf/lX8BCxFvI1dEx7EAAAAASUVORK5CYII=
PNGEND
echo "Created placeholder 32x32 PNG favicon"

# Create 48x48 placeholder
cat > /mnt/user/appdata/film-scheduler-v4/static/images/favicon-48.png << 'PNGEND'
iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAB8ElEQVRoge2ZMW7CQBBFnxGiCB0SRaRLFy6hCheg
ChUVPQfgCJyDI3AEegpKGlSliApRJk2kCImCwr8ZDeuNjZMQQpENK1nG9njn+e3s7loGGhoaGv5lAJyAHbAAhvZ9
CMztuwnQqsPACNgBy5K2tTajOgwMgBnwmCPgBMzRUUhlrMvkDrjNkT8Cd1ZvZ/l12fRKypvncwt0bX9Xq6HLZGDV
iATMLW8a7YZuI9Mqz5q9CrhNDICNVeDaXnyOSJcUCVxUwc6+t53fG44pEriqwpMjASLdm8J3QsAkR2QKjJVfXR+0
HNFcpXgVsDMisaBJ3tEZbQn7HJEXoGf7Pke6V0uJzSrD9EuPmhS0nBbr+vPYBl6B9xL9T+AbeCj570GBbzIUJ7WF
HInIANqOzBR4Qcf9KGdOFKnZCYUROwfGjoyvQjI9W6NQd+aMlLj9mHSN/sWwJ1ND5Bi3gyfH3KG9pshPiQLakxM3
YtZ8h1SLmdlnlEAe9EgXWR1MnXG/i3QS92RqiBTQn4g7p5x1+kcSNUQKiPaxVnykG4QXcnXEd6KvnGcjr4IaIgX0
fQZdCz074zVECujuI+iF1RApoLu07qKqhnwBWsBXjsQX0KrD/5p0uw6kRfaHo0uQfUKMfVNnGxoa/id+ATZTpbm+
ohJ5AAAAAElFTkSuQmCC
PNGEND
echo "Created placeholder 48x48 PNG favicon"

# Create placeholder ICO file (just copying the 32x32 PNG for now)
cp /mnt/user/appdata/film-scheduler-v4/static/images/favicon-32.png /mnt/user/appdata/film-scheduler-v4/static/images/favicon.ico
echo "Created placeholder ICO favicon"

# 4. Update base.html template to include favicon links
if grep -q "favicon" /mnt/user/appdata/film-scheduler-v4/templates/base.html; then
  echo "Favicon links already exist in base.html"
else
  # Make a backup of original base.html
  cp /mnt/user/appdata/film-scheduler-v4/templates/base.html /mnt/user/appdata/film-scheduler-v4/templates/base.html.bak
  
  # Add favicon links to head section using sed
  sed -i '/<head>/a \    <!-- Favicon links -->\n    <link rel="icon" type="image\/svg+xml" href="\/static\/images\/favicon.svg">\n    <link rel="icon" type="image\/png" sizes="32x32" href="\/static\/images\/favicon-32.png">\n    <link rel="icon" type="image\/png" sizes="16x16" href="\/static\/images\/favicon-16.png">\n    <link rel="shortcut icon" href="\/static\/images\/favicon.ico">' /mnt/user/appdata/film-scheduler-v4/templates/base.html
  
  echo "Updated base.html with favicon links"
fi

# 5. Restart the container without rebuilding
echo "Restarting container to apply changes..."
cd /mnt/user/appdata/film-scheduler-v4
docker-compose restart

echo "Favicon implementation complete!"
echo "NOTE: The PNG and ICO files are currently placeholders. For production, you should convert"
echo "      the SVG to proper PNGs and ICO using a tool like Inkscape or an online converter."
