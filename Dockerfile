FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

# Install necessary packages
RUN apt-get install -y \
    ubuntu-mate-desktop \
    tigervnc-standalone-server tigervnc-common \
    git curl wget python3-minimal vim \
    supervisor \
    dbus-x11 \
    xfonts-base xfonts-75dpi xfonts-100dpi \
    sudo

RUN apt-get autopurge -y && rm -rf /var/lib/apt/lists/*

# Download and set up noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify
RUN ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Expose ports for VNC and noVNC
EXPOSE 5901 6080

# Add entrypoint and supervisor config
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]