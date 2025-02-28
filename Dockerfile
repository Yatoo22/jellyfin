FROM ubuntu:22.04

# Prevent interactive dialogs during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    sudo \
    lsb-release \
    wget \
    ca-certificates \
    apt-transport-https \
    software-properties-common

# Add Jellyfin repository
RUN curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -c -s) main" > /etc/apt/sources.list.d/jellyfin.list

# Update and install Jellyfin
RUN apt-get update && \
    apt-get install -y jellyfin

# Install rclone
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    rm rclone-current-linux-amd64.deb

# Create media directories
RUN mkdir -p /media/gdrive

# Setup rclone configuration
RUN mkdir -p /root/.config/rclone
COPY rclone.conf /root/.config/rclone/

# Create custom startup script
RUN echo '#!/bin/bash\n\
# Verify rclone config\n\
export RCLONE_CONFIG=/root/.config/rclone/rclone.conf\n\
echo "Verifying rclone configuration..."\n\
if rclone lsf jellyfin: > /dev/null 2>&1; then\n\
    echo "Successfully connected to Google Drive!"\n\
else\n\
    echo "Error connecting to Google Drive. Check your rclone configuration."\n\
    echo "Available remotes:"\n\
    rclone listremotes\n\
    echo "rclone.conf content:"\n\
    cat $RCLONE_CONFIG\n\
fi\n\
\n\
# Create Jellyfin configuration\n\
mkdir -p /var/lib/jellyfin/config\n\
\n\
# Add Google Drive as media library via path substitution\n\
cat > /var/lib/jellyfin/config/system.xml << EOF\n\
<?xml version="1.0"?>\n\
<ServerConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">\n\
  <EnableUPnP>false</EnableUPnP>\n\
  <PublicPort>8096</PublicPort>\n\
  <PublicHttpsPort>8920</PublicHttpsPort>\n\
  <HttpServerPortNumber>8096</HttpServerPortNumber>\n\
  <HttpsPortNumber>8920</HttpsPortNumber>\n\
  <EnableHttps>false</EnableHttps>\n\
  <IsStartupWizardCompleted>true</IsStartupWizardCompleted>\n\
  <PathSubstitutions>\n\
    <PathSubstitution>\n\
      <From>gdrive://</From>\n\
      <To>rclone://jellyfin:</To>\n\
    </PathSubstitution>\n\
  </PathSubstitutions>\n\
</ServerConfiguration>\n\
EOF\n\
\n\
# Set correct permissions\n\
chown -R jellyfin:jellyfin /var/lib/jellyfin\n\
\n\
# Start Jellyfin\n\
echo "Starting Jellyfin..."\n\
sudo -u jellyfin /usr/bin/jellyfin --webdir=/usr/share/jellyfin/web\n\
' > /start.sh

RUN chmod +x /start.sh

# Expose Jellyfin port
EXPOSE 8096

# Start services
CMD ["/start.sh"]
