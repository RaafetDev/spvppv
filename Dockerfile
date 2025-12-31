FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV NO_VNC_PORT=8080

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
    dbus-x11 \
    novnc \
    python3 \
    python3-numpy \
    websockify \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup VNC
RUN mkdir -p /root/.vnc && \
    echo "password" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create xstartup file
RUN echo '#!/bin/sh' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo 'dbus-launch startxfce4 &' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'export DISPLAY=:1' >> /start.sh && \
    echo 'rm -rf /tmp/.X1-lock /tmp/.X11-unix' >> /start.sh && \
    echo 'mkdir -p /tmp/.X11-unix' >> /start.sh && \
    echo 'chmod 1777 /tmp/.X11-unix' >> /start.sh && \
    echo 'vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None -rfbport 5901' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 8080 localhost:5901' >> /start.sh && \
    chmod +x /start.sh

# Expose noVNC port
EXPOSE 8080

# Start services
CMD ["/start.sh"]
