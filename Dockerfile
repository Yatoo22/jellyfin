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
    wget

# Add Jellyfin repository and install Jellyfin
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -c -s) main" > /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install -y jellyfin

# Install rclone
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    rm rclone-current-linux-amd64.deb

# Create Google Drive mount point
RUN mkdir -p /mnt/gdrive

# Setup rclone configuration in root's home directory
# since the container seems to run as root
RUN mkdir -p /root/.config/rclone
COPY rclone.conf /root/.config/rclone/

# Create startup script
RUN echo '#!/bin/bash\n\
# Mount Google Drive\n\
echo "Mounting Google Drive..."\n\
export RCLONE_CONFIG=/root/.config/rclone/rclone.conf\n\
rclone listremotes\n\
rclone mount jellyfin: /mnt/gdrive --daemon --allow-other --vfs-cache-mode writes\n\
\n\
# Check if mount was successful\n\
sleep 5\n\
if mountpoint -q /mnt/gdrive; then\n\
    echo "Google Drive mounted successfully."\n\
else\n\
    echo "Warning: Failed to mount Google Drive. Check rclone configuration."\n\
    echo "Available remotes:"\n\
    rclone listremotes\n\
    echo "rclone.conf content:"\n\
    cat /root/.config/rclone/rclone.conf\n\
fi\n\
\n\
# Start Jellyfin directly instead of as a service\n\
echo "Starting Jellyfin..."\n\
mkdir -p /var/log/jellyfin\n\
/usr/bin/jellyfin --datadir /var/lib/jellyfin --cachedir /var/cache/jellyfin --logdir /var/log/jellyfin &\n\
\n\
# Keep container running\n\
echo "Services started. Container is now running..."\n\
tail -f /dev/null' > /start.sh

RUN chmod +x /start.sh

# Expose Jellyfin port
EXPOSE 8096

CMD ["/start.sh"]
