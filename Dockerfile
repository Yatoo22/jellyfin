FROM jellyfin/jellyfin

# Install Rclone & FUSE
RUN apt update && apt install -y rclone fuse

# Copy Rclone config (replace with your actual config)
COPY rclone.conf /root/.config/rclone/rclone.conf

# Create media folder
RUN mkdir -p /media/movies

# Mount Google Drive & Start Jellyfin
CMD rclone mount gdrive:/Movies /media/movies --daemon && jellyfin
