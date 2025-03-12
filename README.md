# TurboVNC Docker Image

This repository contains Docker images for TurboVNC with noVNC web interface.

## Features

- TurboVNC server for remote desktop access
- noVNC web interface for browser-based access
- Based on Ubuntu 22.04
- Includes automated testing scripts

## Quick Start

### Build the Docker image

```bash
docker-compose build
```

### Run the container

```bash
docker-compose up -d
```

### Connect to TurboVNC

- VNC client: `localhost:5901`
- Web browser: `http://localhost:6080/vnc.html`

## Testing

The repository includes several test scripts to verify functionality:

### Basic Connection Test

```bash
./tests/connection_test.sh
```

### Xvfb Connection Test

```bash
./tests/xvfb_connection_test.sh
```

### Performance Test

```bash
./tests/performance_test.sh
```

### Security Test

```bash
./tests/security_test.sh
```

## About TurboVNC

TurboVNC is a high-performance VNC implementation that is tuned for 3D and video workloads. It provides a unique combination of performance and compatibility that makes it particularly suited for remote 3D applications.

Key features of TurboVNC include:
- Optimized for 3D and video performance
- Supports hardware-accelerated OpenGL applications
- Includes advanced compression algorithms
- Maintained by The VirtualGL Project

## License

This project is licensed under the MIT License - see the LICENSE file for details. 