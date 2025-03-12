# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# TURBOVNC STAGE: Adds TurboVNC server on top of the base image
# -----------------------------------------------------------------------------
ARG BASE_IMAGE=turbovnc-base:latest
FROM ${BASE_IMAGE} AS vnc

# Set shell options for safety
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install TurboVNC dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libxtst6 \
    libxv1 \
    libglu1-mesa \
    libc6 \
    libegl1 \
    libstdc++6 \
    libx11-6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Download and install TurboVNC
ENV TURBOVNC_VERSION=3.0.3
ENV TURBOVNC_BUILD=20230706
ENV TURBOVNC_DOWNLOAD_URL=https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download

WORKDIR /tmp
RUN curl -fsSL -o turbovnc.deb "${TURBOVNC_DOWNLOAD_URL}" && \
    dpkg -i turbovnc.deb && \
    rm turbovnc.deb && \
    ln -s /opt/TurboVNC/bin/vncserver /usr/bin/turbovncserver && \
    ln -s /opt/TurboVNC/bin/vncviewer /usr/bin/turbovncviewer && \
    echo "export TURBOVNC_VERSION_INFO=${TURBOVNC_VERSION}-${TURBOVNC_BUILD}" > /etc/turbovnc-version

# Add VNC-specific metadata
LABEL org.opencontainers.image.base.name="turbovnc-base" \
      org.opencontainers.image.title="turbovnc-devenv" \
      org.opencontainers.image.description="TurboVNC server environment" \
      org.opencontainers.image.source="https://github.com/drengskapur/turbovnc"

# Add version as a separate label
RUN . /etc/turbovnc-version && \
    echo "LABEL org.opencontainers.image.version=\"${TURBOVNC_VERSION_INFO}\"" >> /etc/docker-labels

# Set environment variable for the VNC version
RUN . /etc/turbovnc-version && \
    echo "ENV VNC_VERSION=${TURBOVNC_VERSION_INFO}" >> /etc/docker-labels

# Configure VNC using common config
RUN mkdir -p /etc/vnc/turbovnc && \
    cp /etc/vnc/common/config /etc/vnc/turbovnc/config

# Configure supervisord for TurboVNC
RUN echo "[program:vnc]" > /etc/supervisor/conf.d/vnc.conf && \
    echo "command=/opt/TurboVNC/bin/vncserver -xstartup /usr/bin/xterm -noreset -fg -SecurityTypes None --I-KNOW-THIS-IS-INSECURE :1" >> /etc/supervisor/conf.d/vnc.conf && \
    echo "autostart=true" >> /etc/supervisor/conf.d/vnc.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/vnc.conf && \
    echo "stdout_logfile=/var/log/supervisor/vnc.log" >> /etc/supervisor/conf.d/vnc.conf && \
    echo "stderr_logfile=/var/log/supervisor/vnc.err" >> /etc/supervisor/conf.d/vnc.conf

# -----------------------------------------------------------------------------
# NOVNC STAGE: Adds noVNC web client on top of VNC
# -----------------------------------------------------------------------------
FROM vnc AS novnc

# Import version info from previous stage
COPY --from=vnc /etc/turbovnc-version /etc/turbovnc-version
COPY --from=vnc /etc/docker-labels /etc/docker-labels

# Add noVNC-specific metadata
LABEL org.opencontainers.image.base.name="turbovnc-devenv" \
      org.opencontainers.image.title="turbovnc-novnc-devenv" \
      org.opencontainers.image.description="TurboVNC with noVNC web client" \
      org.opencontainers.image.source="https://github.com/drengskapur/turbovnc"

# Install and configure noVNC
WORKDIR /usr/local/share
RUN git clone https://github.com/novnc/noVNC.git novnc

# Add version info - moved after git clone
WORKDIR /usr/local/share/novnc
RUN . /etc/turbovnc-version && \
    NOVNC_VERSION=$(git describe --tags) && \
    echo "LABEL org.opencontainers.image.version=\"turbovnc-${TURBOVNC_VERSION_INFO}-novnc-${NOVNC_VERSION}\"" >> /etc/docker-labels

# Apply all labels
LABEL org.opencontainers.image.version="turbovnc-novnc"

# Add noVNC environment variables
ENV NOVNC_PORT=6080

# Configure noVNC
RUN NOVNC_VERSION=$(git describe --tags) && \
    git checkout "${NOVNC_VERSION}" && \
    cp vnc.html index.html && \
    echo "/* Use default styling */" > app/styles/custom.css

# Use the noVNC supervisor config template
RUN cp /etc/supervisor/conf.d/novnc.conf.template /etc/supervisor/conf.d/novnc.conf

# Reset working directory to root
WORKDIR /

# Expose noVNC port
EXPOSE 6080

# Update health check for noVNC
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:6080 || exit 1 