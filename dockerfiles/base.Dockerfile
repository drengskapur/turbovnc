# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# BASE STAGE: Just the OS and core packages
# -----------------------------------------------------------------------------
FROM ubuntu:22.04 AS base_os

# BASE STAGE: Just the OS and core packages
ARG DEBIAN_FRONTEND=noninteractive

# Set shell options for safety
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Capture Ubuntu version information
RUN . /etc/os-release && \
    echo "export UBUNTU_VERSION=${VERSION_ID}" > /etc/ubuntu-version

# Add base metadata
LABEL org.opencontainers.image.base.name="ubuntu" \
      org.opencontainers.image.version="22.04" \
      org.opencontainers.image.description="Base Ubuntu image for TurboVNC implementation" \
      org.opencontainers.image.source="https://github.com/drengskapur/turbovnc"

# Install base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    bash \
    ca-certificates \
    curl \
    dbus-x11 \
    gnupg \
    locales \
    net-tools \
    python3 \
    python3-pip \
    software-properties-common \
    sudo \
    supervisor \
    wget \
    xauth \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Create app directory
RUN mkdir -p /app

# Set up supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d \
    && mkdir -p /var/log/supervisor \
    && echo "[supervisord]" > /etc/supervisor/supervisord.conf \
    && echo "nodaemon=true" >> /etc/supervisor/supervisord.conf \
    && echo "logfile=/var/log/supervisor/supervisord.log" >> /etc/supervisor/supervisord.conf \
    && echo "pidfile=/var/run/supervisord.pid" >> /etc/supervisor/supervisord.conf \
    && echo "childlogdir=/var/log/supervisor" >> /etc/supervisor/supervisord.conf \
    && echo "" >> /etc/supervisor/supervisord.conf \
    && echo "[include]" >> /etc/supervisor/supervisord.conf \
    && echo "files = /etc/supervisor/conf.d/*.conf" >> /etc/supervisor/supervisord.conf \
    && echo "" >> /etc/supervisor/supervisord.conf \
    && echo "[supervisorctl]" >> /etc/supervisor/supervisord.conf \
    && echo "serverurl=unix:///tmp/supervisor.sock" >> /etc/supervisor/supervisord.conf

# -----------------------------------------------------------------------------
# VNC BASE STAGE: Common VNC setup, without a specific implementation
# -----------------------------------------------------------------------------
FROM ubuntu:22.04 AS vnc-base

# Set shell options for safety
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add VNC base metadata
LABEL org.opencontainers.image.base.name="turbovnc-base" \
      org.opencontainers.image.description="Base TurboVNC image with common dependencies" \
      org.opencontainers.image.source="https://github.com/drengskapur/turbovnc"

# Install common VNC-related packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    git \
    xauth \
    xorg \
    xterm \
    supervisor \
    ffmpeg \
    python3 \
    python3-pip \
    python3-websockify \
    dbus-x11 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC directories
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /etc/vnc/common && \
    echo "SecurityTypes=None" > /etc/vnc/common/config && \
    echo "localhost=no" >> /etc/vnc/common/config

# Create common entrypoint script
RUN echo "#!/bin/bash" > /usr/local/bin/entrypoint.sh && \
    echo "set -e" >> /usr/local/bin/entrypoint.sh && \
    echo "" >> /usr/local/bin/entrypoint.sh && \
    echo "log() {" >> /usr/local/bin/entrypoint.sh && \
    echo "    echo \"\$(date '+%Y-%m-%d %H:%M:%S') - \$1\"" >> /usr/local/bin/entrypoint.sh && \
    echo "}" >> /usr/local/bin/entrypoint.sh && \
    echo "" >> /usr/local/bin/entrypoint.sh && \
    echo "log \"Starting TurboVNC services\"" >> /usr/local/bin/entrypoint.sh && \
    echo "" >> /usr/local/bin/entrypoint.sh && \
    echo "# Start supervisor in foreground mode" >> /usr/local/bin/entrypoint.sh && \
    echo "exec supervisord -n -c /etc/supervisor/supervisord.conf" >> /usr/local/bin/entrypoint.sh && \
    echo "" >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Configure noVNC supervisor template
RUN echo "[program:novnc]" > /etc/supervisor/conf.d/novnc.conf.template && \
    echo "command=websockify --web=/usr/local/share/novnc %(ENV_NOVNC_PORT)s localhost:5901" >> /etc/supervisor/conf.d/novnc.conf.template && \
    echo "autostart=true" >> /etc/supervisor/conf.d/novnc.conf.template && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/novnc.conf.template && \
    echo "stdout_logfile=/var/log/supervisor/novnc.log" >> /etc/supervisor/conf.d/novnc.conf.template && \
    echo "stderr_logfile=/var/log/supervisor/novnc.err" >> /etc/supervisor/conf.d/novnc.conf.template

# Set working directory
WORKDIR /

# Default entrypoint and command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Add version info from Ubuntu version file
COPY --from=base_os /etc/ubuntu-version /etc/ubuntu-version

# Set image labels directly
# Note: Labels must be added as Dockerfile instructions, not shell commands
LABEL org.opencontainers.image.base.name="ubuntu-22.04"
LABEL org.opencontainers.image.version="turbovnc-base"

# Default VNC port
EXPOSE 5901

# Default health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD pgrep -f "vnc" || exit 1 