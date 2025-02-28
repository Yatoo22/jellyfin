# Use Ubuntu 22.04 (LTS) instead of the latest version
FROM ubuntu:22.04

# Set non-interactive mode to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt install -y \
    curl \
    gnupg \
    software-properties-common \
    rclone \
    fuse \
    && rm -rf /var/lib/apt/lists/*

# Add Jellyfin repository manually (Ubuntu 22.04)
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg \
    && echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu jammy main" | tee /etc/apt/sources.list.d/jellyfin.list \
    && apt update && apt install -y jellyfin \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /mnt/gdrive /root/.config/rclone

# Copy rclone.conf into the container (Make sure it's in the same directory as the Dockerfile)
COPY rclone.conf /root/.config/rclone/rclone.conf

# Expose Jellyfin port
EXPOSE 8096

# Start Rclone and Jellyfin
CMD ["bash", "-c", "rclone mount jellyfin: /mnt/gdrive --config=/root/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes --daemon && jellyfin --no-browser"]
