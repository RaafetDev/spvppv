FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root
ENV DISPLAY=:1

# Install system packages, XFCE, VNC server, and noVNC
RUN apt-get update && apt-get install -y \
    sudo \
    ssh \
    wget \
    curl \
    git \
    vim \
    nano \
    net-tools \
    supervisor \
    xfce4 \
    xfce4-terminal \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    python3 \
    python3-numpy \
    websockify \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC directory and set password
RUN mkdir -p ~/.vnc && \
    echo "password" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Configure VNC xstartup
RUN echo '#!/bin/sh' > ~/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> ~/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> ~/.vnc/xstartup && \
    echo 'exec startxfce4' >> ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Create supervisor config
RUN mkdir -p /var/log/supervisor
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:vncserver]
command=/usr/bin/vncserver :1 -geometry 1280x720 -depth 24 -localhost no
autorestart=true
stdout_logfile=/var/log/supervisor/vncserver.log
stderr_logfile=/var/log/supervisor/vncserver_err.log

[program:novnc]
command=/usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:8080
autorestart=true
stdout_logfile=/var/log/supervisor/novnc.log
stderr_logfile=/var/log/supervisor/novnc_err.log
EOF

# Expose noVNC port
EXPOSE 8080

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
