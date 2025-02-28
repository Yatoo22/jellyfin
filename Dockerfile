FROM ubuntu:22.04

# Prevent interactive dialogs during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    sudo \
    fuse \
    lsb-release \
    nano \
    wget \
    ca-certificates \
    procps

# Add Jellyfin repository and install Jellyfin with proper web content
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -c -s) main" > /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install -y jellyfin jellyfin-web

# Install rclone
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    rm rclone-current-linux-amd64.deb

# Create Google Drive mount point
RUN mkdir -p /mnt/gdrive

# Setup rclone configuration in root's home directory
RUN mkdir -p /root/.config/rclone
COPY rclone.conf /root/.config/rclone/

# Create startup script with improved mount handling
RUN echo '#!/bin/bash\n\
# Set full permissions for FUSE\n\
modprobe fuse || echo "Failed to load FUSE module - might need privileged container"\n\
\n\
# Mount Google Drive without daemon mode\n\
echo "Mounting Google Drive..."\n\
export RCLONE_CONFIG=/root/.config/rclone/rclone.conf\n\
mkdir -p /mnt/gdrive\n\
\n\
# Start rclone mount in background but not as daemon\n\
rclone mount jellyfin: /mnt/gdrive --allow-other --vfs-cache-mode writes &\n\
RCLONE_PID=$!\n\
\n\
# Give it a moment to mount\n\
sleep 3\n\
\n\
# Check if mount was successful\n\
if mountpoint -q /mnt/gdrive || ls -la /mnt/gdrive; then\n\
    echo "Google Drive mounted successfully."\n\
else\n\
    echo "Warning: Failed to mount Google Drive. Check rclone configuration."\n\
    echo "Available remotes:"\n\
    rclone listremotes\n\
    echo "rclone.conf content:"\n\
    cat /root/.config/rclone/rclone.conf\n\
    echo "Starting Jellyfin anyway..."\n\
fi\n\
\n\
# Start Jellyfin\n\
echo "Starting Jellyfin..."\n\
mkdir -p /var/log/jellyfin\n\
/usr/bin/jellyfin --datadir /var/lib/jellyfin --cachedir /var/cache/jellyfin --logdir /var/log/jellyfin &\n\
JELLYFIN_PID=$!\n\
\n\
# Monitor both processes\n\
echo "Services started. Container is now running..."\n\
wait $JELLYFIN_PID\n\
' > /start.sh

RUN chmod +x /start.sh

# Expose Jellyfin port
EXPOSE 8096

CMD ["/start.sh"]
