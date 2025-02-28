FROM ubuntu:latest

# Set DEBIAN_FRONTEND to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt update && apt install -y \
    curl \
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Add Jellyfin repository
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg \
    && echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/jellyfin.list \
    && apt update && apt install -y jellyfin rclone fuse \
    && rm -rf /var/lib/apt/lists/*

# Create mount directory
RUN mkdir -p /mnt/gdrive /root/.config/rclone

# Expose Jellyfin port
EXPOSE 8096

# Run Jellyfin and Rclone Mount
CMD ["/bin/bash", "-c", "cp /rclone.conf /root/.config/rclone/rclone.conf && rclone mount jellyfin: /mnt/gdrive --config=/root/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes --daemon && systemctl start jellyfin && tail -f /dev/null"]
