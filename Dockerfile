FROM ubuntu:latest

# Install dependencies
RUN apt update -y && apt install -y \
    jellyfin \
    rclone \
    fuse \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy Rclone config (Make sure you have this file in your repo)
COPY rclone.conf /root/.config/rclone/rclone.conf

# Create a media directory
RUN mkdir -p /media/movies

# Expose Jellyfin's default port
EXPOSE 8096

# Run Rclone mount and start Jellyfin
CMD rclone mount jellyfin:/Movies /media/movies --daemon && jellyfin --no-auth
