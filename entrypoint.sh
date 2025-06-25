#!/bin/bash
set -e

USER=${USER:-developer}
PASSWORD=${PASSWORD:-password}
RESOLUTION=${RESOLUTION:-1280x800}

# Create user if not exists
if ! id -u "${USER}" >/dev/null 2>&1; then
    useradd -m "${USER}"
    echo "${USER}:$PASSWORD" | chpasswd
    adduser "${USER}" sudo
fi

# Set VNC password
mkdir -p "/home/${USER}/.vnc"
echo "$PASSWORD" | vncpasswd -f > "/home/${USER}/.vnc/passwd"

# Set up VNC configuration
cat > "/home/${USER}/.vnc/config" <<EOF
session=mate
geometry=${RESOLUTION}
localhost=no
alwaysshared
EOF

# Create xstartup script for MATE
cat > "/home/${USER}/.vnc/xstartup" <<EOF
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR=/tmp/runtime-${USER}
mkdir -p \$XDG_RUNTIME_DIR
chmod 700 \$XDG_RUNTIME_DIR
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=MATE
dbus-launch --exit-with-session mate-session
EOF

# Set proper permissions
chown -R "${USER}:${USER}" "/home/${USER}/.vnc"
chmod 755 "/home/${USER}/.vnc/xstartup"
chmod 600 "/home/${USER}/.vnc/passwd"
chmod 644 "/home/${USER}/.vnc/config"

# Create .Xauthority file
su - "${USER}" -c "touch /home/${USER}/.Xauthority"

# Kill any existing VNC sessions
su - "${USER}" -c "vncserver -kill :1" || true

# Clean up any leftover lock files
rm -f "/tmp/.X1-lock" "/tmp/.X11-unix/X1" || true

# Start VNC server once to initialize it properly
su - "${USER}" -c "cd /home/${USER} && vncserver :1 -geometry ${RESOLUTION} -depth 24 -localhost no -xstartup /home/${USER}/.vnc/xstartup" || true
sleep 2
su - "${USER}" -c "vncserver -kill :1" || true

# Write supervisord.conf dynamically
cat >/etc/supervisord.conf <<EOF
[supervisord]
nodaemon=true
user=root

[program:vncserver]
command=su - ${USER} -c "cd /home/${USER} && vncserver :1 -geometry ${RESOLUTION} -depth 24 -localhost no -xstartup /home/${USER}/.vnc/xstartup"
autostart=true
autorestart=true
stdout_logfile=/var/log/vncserver.log
stderr_logfile=/var/log/vncserver_err.log
startretries=3
startsecs=10

[program:novnc]
command=/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080 --web /opt/noVNC
user=${USER}
autostart=true
autorestart=true
stdout_logfile=/var/log/novnc.log
stderr_logfile=/var/log/novnc_err.log
EOF

exec /usr/bin/supervisord -c /etc/supervisord.conf