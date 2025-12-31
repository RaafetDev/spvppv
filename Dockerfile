FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root
ENV DISPLAY=:1

# Install system packages, XFCE, VNC server, and noVNC
RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    curl \
    git \
    vim \
    nano \
    net-tools \
    xfce4 \
    xfce4-terminal \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    dbus-x11 \
    novnc \
    python3 \
    websockify \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup VNC
RUN mkdir -p /root/.vnc && \
    echo "password" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create xstartup file
RUN echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo 'exec startxfce4' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Clean up any existing locks' >> /start.sh && \
    echo 'rm -rf /tmp/.X1-lock /tmp/.X11-unix' >> /start.sh && \
    echo 'mkdir -p /tmp/.X11-unix' >> /start.sh && \
    echo 'chmod 1777 /tmp/.X11-unix' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC server' >> /start.sh && \
    echo 'echo "Starting VNC server..."' >> /start.sh && \
    echo 'vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None -rfbport 5901 -localhost yes --I-KNOW-THIS-IS-INSECURE' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait for VNC to be ready' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Check if VNC is running' >> /start.sh && \
    echo 'if ! pgrep -x "Xtigervnc" > /dev/null; then' >> /start.sh && \
    echo '    echo "ERROR: VNC server failed to start"' >> /start.sh && \
    echo '    cat /root/.vnc/*.log' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start noVNC' >> /start.sh && \
    echo 'echo "Starting noVNC web server..."' >> /start.sh && \
    echo 'cd /usr/share/novnc' >> /start.sh && \
    echo 'ln -sf vnc.html index.html' >> /start.sh && \
    echo 'exec /usr/bin/websockify --web /usr/share/novnc 8080 127.0.0.1:5901' >> /start.sh && \
    chmod +x /start.sh

# Expose noVNC port
EXPOSE 8080

# Start services
CMD ["/start.sh"]
