#!/bin/bash
# Run all TurboVNC tests and generate a report

set -e

# Create a report directory
REPORT_DIR="test_reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/turbovnc_test_report_$TIMESTAMP.md"

mkdir -p $REPORT_DIR

# Start containers if not already running
if ! docker ps | grep -q turbovnc; then
  echo "Starting containers with docker-compose..."
  docker-compose up -d
  sleep 10  # Give containers time to start
fi

# Function to run a test and capture output
run_test() {
  local test_script=$1
  local test_name=$2
  
  echo "Running $test_name..."
  
  # Run the test and capture output
  output=$(bash $test_script 2>&1)
  exit_code=$?
  
  # Add to report
  echo "## $test_name" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "Exit code: $exit_code" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo '```' >> "$REPORT_FILE"
  echo "$output" >> "$REPORT_FILE"
  echo '```' >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  
  return $exit_code
}

# Initialize report
echo "# TurboVNC Test Report - $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Environment" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- Date: $(date)" >> "$REPORT_FILE"
echo "- Host: $(hostname)" >> "$REPORT_FILE"
echo "- Docker version: $(docker --version)" >> "$REPORT_FILE"
echo "- Docker Compose version: $(docker-compose --version)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Get container information
echo "## Container Information" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### TurboVNC Container" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
docker inspect turbovnc | grep -E 'Image|Status|Health|Port' >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Run tests
run_test "./tests/connection_test.sh" "Connection Test"
CONNECTION_RESULT=$?

run_test "./tests/performance_test.sh" "Performance Test"
PERFORMANCE_RESULT=$?

# Add summary to report
echo "## Summary" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Test | Result |" >> "$REPORT_FILE"
echo "|------|--------|" >> "$REPORT_FILE"
if [ $CONNECTION_RESULT -eq 0 ]; then
  echo "| Connection Test | ✅ PASSED |" >> "$REPORT_FILE"
else
  echo "| Connection Test | ❌ FAILED |" >> "$REPORT_FILE"
fi

if [ $PERFORMANCE_RESULT -eq 0 ]; then
  echo "| Performance Test | ✅ PASSED |" >> "$REPORT_FILE"
else
  echo "| Performance Test | ❌ FAILED |" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Print report location
echo "Test report generated: $REPORT_FILE"

# Exit with success only if all tests passed
if [ $CONNECTION_RESULT -eq 0 ] && [ $PERFORMANCE_RESULT -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed. See report for details."
  exit 1
fi 