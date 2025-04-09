#!/bin/bash
echo "Checking current file states..."

# Check app.py for our changes
echo "Checking app.py..."
if grep -q "regenerate_calendar.*yes" /mnt/user/appdata/film-scheduler-v4/app.py; then
  echo "✅ app.py appears to have our changes"
else
  echo "❌ app.py does NOT contain our changes"
fi

# Check for delete button
echo "Checking dashboard.html..."
if grep -q "delete-project" /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html; then
  echo "✅ delete button was added to dashboard.html"
else
  echo "❌ delete button was NOT added to dashboard.html"
fi

# Check for confirmation script
echo "Checking calendar.html..."
if grep -q "Regenerating the calendar will reset" /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html; then
  echo "✅ confirmation dialog was added to calendar.html"
else
  echo "❌ confirmation dialog was NOT added to calendar.html"
fi

# Check for version number fix
echo "Checking if meta-group with Version exists..."
if grep -q '<div class="meta-label">Version</div>' /mnt/user/appdata/film-scheduler-v4/templates/viewer.html; then
  echo "❌ Old version number still exists in viewer.html"
else
  echo "✅ Old version number was removed from viewer.html"
fi

# Check file ownership and permissions
echo "Checking file permissions..."
ls -la /mnt/user/appdata/film-scheduler-v4/app.py
ls -la /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html
ls -la /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html
