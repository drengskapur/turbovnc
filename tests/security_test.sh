#!/bin/bash
# Basic security test for TurboVNC implementation

# Start Xvfb with a virtual display
Xvfb :1 -screen 0 1024x768x24 &
XVFB_PID=$!

# Wait for Xvfb to initialize
sleep 2

# Define VNC commands
VNC_SERVER="/opt/TurboVNC/bin/vncserver"
VNC_VIEWER="/opt/TurboVNC/bin/vncviewer"

echo "Testing security types..."

# Test 1: None authentication
$VNC_SERVER :1 -SecurityTypes None
sleep 2
echo "Connecting with no authentication..."
$VNC_VIEWER -SecurityTypes None localhost:1 &
VIEWER_PID=$!
sleep 3
kill $VIEWER_PID
$VNC_SERVER -kill :1
echo "No auth test complete"

# Test 2: VNC authentication
echo "secret123" | vncpasswd -f > /tmp/vncpass
$VNC_SERVER :1 -SecurityTypes VncAuth -passwordfile /tmp/vncpass
sleep 2
echo "Connecting with VNC authentication..."
echo "secret123" | $VNC_VIEWER -SecurityTypes VncAuth localhost:1 &
VIEWER_PID=$!
sleep 3
kill $VIEWER_PID
$VNC_SERVER -kill :1
echo "VNC auth test complete"

# Test 3: Wrong password (should fail)
echo "wrongpass" | vncpasswd -f > /tmp/vncwrongpass
$VNC_SERVER :1 -SecurityTypes VncAuth -passwordfile /tmp/vncpass
sleep 2
echo "Testing wrong password (should fail)..."
echo "wrongpass" | $VNC_VIEWER -SecurityTypes VncAuth localhost:1 &
VIEWER_PID=$!
sleep 3
# Check if viewer is still running (it should have failed to connect)
if kill -0 $VIEWER_PID 2>/dev/null; then
  echo "❌ Security test failed: Connected with wrong password"
  kill $VIEWER_PID
  $VNC_SERVER -kill :1
  kill $XVFB_PID
  rm /tmp/vncpass /tmp/vncwrongpass
  exit 1
else
  echo "✅ Security test passed: Wrong password rejected"
fi

$VNC_SERVER -kill :1
kill $XVFB_PID
rm /tmp/vncpass /tmp/vncwrongpass
echo "Security tests completed successfully"
exit 0 