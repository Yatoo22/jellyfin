# Use an official Ubuntu base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    software-properties-common \
    fuse \
    rclone \
    systemd \
    && apt-get clean

# Add Jellyfin repository and install Jellyfin
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && apt-get install -y jellyfin

# Create mount directory for Google Drive
RUN mkdir -p /mnt/gdrive

# Copy rclone configuration file
COPY rclone.conf /root/.config/rclone/rclone.conf

# Add systemd service for rclone
RUN echo "[Unit]\n\
Description=Rclone Mount Google Drive\n\
After=network-online.target\n\
Wants=network-online.target\n\
\n\
[Service]\n\
Type=simple\n\
ExecStart=/usr/bin/rclone mount jellyfin: /mnt/gdrive \\\n\
    --config=/root/.config/rclone/rclone.conf \\\n\
    --allow-other \\\n\
    --vfs-cache-mode writes\n\
ExecStop=/bin/fusermount -u /mnt/gdrive\n\
Restart=always\n\
User=root\n\
Group=root\n\
\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/rclone-gdrive.service

# Enable and start the rclone service
RUN systemctl enable rclone-gdrive

# Expose Jellyfin default port
EXPOSE 8096

# Start Jellyfin and rclone services
CMD ["bash", "-c", "systemctl start rclone-gdrive && jellyfin"]
