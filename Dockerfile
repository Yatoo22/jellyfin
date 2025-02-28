# Use an official Ubuntu base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and add Jellyfin repository
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    software-properties-common \
    fuse && \
    curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/jellyfin.gpg arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && apt-get install -y jellyfin && \
    apt-get clean

# Manually download and install rclone
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cd rclone-*-linux-amd64 && \
    cp rclone /usr/bin/ && \
    chmod +x /usr/bin/rclone && \
    rm -rf rclone-current-linux-amd64.zip rclone-*-linux-amd64

# Create mount directory for Google Drive
RUN mkdir -p /mnt/gdrive

# Copy rclone configuration file
COPY rclone.conf /root/.config/rclone/rclone.conf

# Expose Jellyfin default port
EXPOSE 8096

# Start rclone and Jellyfin directly
CMD bash -c "rclone mount jellyfin: /mnt/gdrive --config=/root/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes & jellyfin"
