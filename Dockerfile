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
    jellyfin \
    && apt-get clean

# Create mount directory for Google Drive
RUN mkdir -p /mnt/gdrive

# Copy rclone configuration file
COPY rclone.conf /root/.config/rclone/rclone.conf

# Expose Jellyfin default port
EXPOSE 8096

# Start rclone and Jellyfin directly
CMD bash -c "rclone mount jellyfin: /mnt/gdrive --config=/root/.config/rclone/rclone.conf --allow-other --vfs-cache-mode writes & jellyfin"
