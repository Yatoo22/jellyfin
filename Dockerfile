FROM jellyfin/jellyfin

RUN apt update && apt install -y rclone fuse

COPY rclone.conf /root/.config/rclone/rclone.conf

RUN mkdir -p /media/movies

CMD rclone mount gdrive:/Movies /media/movies --daemon && jellyfin
