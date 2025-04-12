#!/bin/bash
# Save the current working state in Git with a proper commit and tag

# Navigate to your project directory
cd /mnt/user/appdata/film-scheduler-v4

# Check current Git status
echo "Current Git status:"
git status

# Create a new branch for this stable version (optional, but recommended)
# Skip this if you're already on a feature branch you want to keep
git checkout -b stable-working-version

# Stage all changes
git add .

# Commit with a descriptive message
git commit -m "Fixed project info display with proper layout and styling while preserving drag-and-drop functionality"

# Create a tag for easy reference later
git tag -a v1.0-stable -m "Stable working version with all critical features"

# Show the commit and tag
echo "New commit created:"
git log -n 1

echo "New tag created:"
git tag -l -n1 v1.0-stable

echo "----------------------------------------"
echo "This version is now saved in Git."
echo "To return to this version in the future, use either:"
echo "  git checkout v1.0-stable    # To temporarily check out this version"
echo "  git reset --hard v1.0-stable # To reset your current branch to this version"
echo "----------------------------------------"

# Optional: Push to remote repository if you have one
# Uncomment these lines if you want to push your changes
# echo "Push changes to remote? (y/n)"
# read PUSH_CHOICE
# if [ "$PUSH_CHOICE" = "y" ]; then
#   git push origin stable-working-version
#   git push origin v1.0-stable
#   echo "Changes and tag pushed to remote repository"
# fi
