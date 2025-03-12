#!/bin/bash
# TurboVNC connection test

set -e

# Function to test VNC connection
test_vnc_connection() {
  local container_name=$1
  local vnc_port=$2
  local novnc_port=$3
  
  echo "Testing connection to $container_name..."
  
  # Check if container is running
  if ! docker ps | grep -q $container_name; then
    echo "❌ Container $container_name is not running"
    return 1
  fi
  
  # Test VNC port
  if nc -z localhost $vnc_port; then
    echo "✅ VNC port $vnc_port is open"
  else
    echo "❌ VNC port $vnc_port is not accessible"
    return 1
  fi
  
  # Test noVNC port
  if curl -s http://localhost:$novnc_port > /dev/null; then
    echo "✅ noVNC web interface on port $novnc_port is accessible"
  else
    echo "❌ noVNC web interface on port $novnc_port is not accessible"
    return 1
  fi
  
  # Check container logs for errors
  if docker logs $container_name 2>&1 | grep -i "error\|fatal\|failed"; then
    echo "⚠️ Found errors in container logs"
  else
    echo "✅ No errors found in container logs"
  fi
  
  echo "✅ Connection test for $container_name passed"
  return 0
}

# Start container if not already running
if ! docker ps | grep -q turbovnc; then
  echo "Starting TurboVNC container..."
  docker-compose up -d turbovnc
  sleep 10  # Give container time to start
fi

# Test TurboVNC container
echo "=== Testing TurboVNC ==="
test_vnc_connection "turbovnc" 5901 6080
TURBO_RESULT=$?

# Summary
echo "=== Test Summary ==="
if [ $TURBO_RESULT -eq 0 ]; then
  echo "TurboVNC: PASSED"
  exit 0
else
  echo "TurboVNC: FAILED"
  exit 1
fi 