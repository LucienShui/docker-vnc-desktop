FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    ubuntu-mate-desktop \
    tigervnc-standalone-server tigervnc-common \
    wget python3-minimal \
    git curl supervisor \
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

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