#!/bin/bash

# Set up rclone configuration
export RCLONE_CONFIG=/home/media-user/.config/rclone/rclone.conf

# Check if environment variables are set
if [ -n "$GDRIVE_CLIENT_ID" ] && [ -n "$GDRIVE_CLIENT_SECRET" ] && [ -n "$GDRIVE_TOKEN" ]; then
    echo "Using provided Google Drive credentials from environment variables..."
    # Replace environment variables in the template
    cat /home/media-user/.config/rclone/rclone.conf.template | \
    sed "s|\${GDRIVE_CLIENT_ID}|$GDRIVE_CLIENT_ID|g" | \
    sed "s|\${GDRIVE_CLIENT_SECRET}|$GDRIVE_CLIENT_SECRET|g" | \
    sed "s|\${GDRIVE_TOKEN}|$GDRIVE_TOKEN|g" | \
    sed "s|\${GDRIVE_TEAM_ID}|$GDRIVE_TEAM_ID|g" | \
    sed "s|\${GDRIVE_FOLDER_ID}|$GDRIVE_FOLDER_ID|g" > $RCLONE_CONFIG
else
    echo "Google Drive credentials not found in environment variables."
    echo "You'll need to configure rclone manually by:"
    echo "1. Connecting to this container"
    echo "2. Running: rclone config"
    echo "3. Setting up your Google Drive connection"
    echo "4. Restarting the container"
    
    # Create a minimal config so the container doesn't crash
    echo "[gdrive]" > $RCLONE_CONFIG
    echo "type = drive" >> $RCLONE_CONFIG
fi

# Try to mount Google Drive
echo "Attempting to mount Google Drive..."
rclone mount gdrive: /mnt/gdrive --daemon --allow-other --vfs-cache-mode writes

# If mount successful, set permissions
if [ $? -eq 0 ]; then
    echo "Google Drive mounted successfully."
    # Set Jellyfin media library permissions
    chown -R media-user:media-user /mnt/gdrive
else
    echo "Warning: Failed to mount Google Drive. Check your rclone configuration."
fi

# Start Jellyfin
echo "Starting Jellyfin..."
sudo service jellyfin start

# Keep the container running
echo "Services started. Container is now running..."
tail -f /dev/null
