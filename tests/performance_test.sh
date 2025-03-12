#!/bin/bash
# Performance test for TurboVNC Docker container

set -e

# Function to measure response time
measure_response_time() {
  local container_name=$1
  local novnc_port=$2
  local iterations=10
  local total_time=0
  
  echo "Measuring response time for $container_name..."
  
  # Check if container is running
  if ! docker ps | grep -q $container_name; then
    echo "❌ Container $container_name is not running"
    return 1
  fi
  
  # Measure response time for noVNC web interface
  for i in $(seq 1 $iterations); do
    start_time=$(date +%s.%N)
    curl -s http://localhost:$novnc_port > /dev/null
    end_time=$(date +%s.%N)
    
    # Calculate time difference
    time_diff=$(echo "$end_time - $start_time" | bc)
    total_time=$(echo "$total_time + $time_diff" | bc)
    
    echo "  Request $i: $time_diff seconds"
  done
  
  # Calculate average
  avg_time=$(echo "scale=3; $total_time / $iterations" | bc)
  echo "Average response time: $avg_time seconds"
  
  # Store result for comparison
  echo $avg_time > /tmp/turbovnc_response_time.txt
  
  return 0
}

# Start container if not already running
if ! docker ps | grep -q turbovnc; then
  echo "Starting container with docker-compose..."
  docker-compose up -d
  sleep 10  # Give container time to start
fi

# Test TurboVNC container
echo "=== Performance Testing TurboVNC ==="
measure_response_time "turbovnc" 6080
TURBO_RESULT=$?

# Display results
if [ $TURBO_RESULT -eq 0 ]; then
  TURBO_TIME=$(cat /tmp/turbovnc_response_time.txt)
  
  echo "=== Performance Results ==="
  echo "TurboVNC average response time: $TURBO_TIME seconds"
fi

# Cleanup
rm -f /tmp/turbovnc_response_time.txt

# Exit with success
exit 0 