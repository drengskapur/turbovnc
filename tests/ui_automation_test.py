#!/usr/bin/env python3
import subprocess
import time
import pyautogui
import os
import sys

def run_vnc_ui_test():
    """Run automated UI tests on TurboVNC connection"""
    # Start VNC server
    server_cmd = ["/opt/TurboVNC/bin/vncserver", ":1", "-geometry", "1024x768"]
    viewer_cmd = ["/opt/TurboVNC/bin/vncviewer", "localhost:1"]
    
    subprocess.run(server_cmd)
    time.sleep(3)
    
    # Start viewer
    viewer = subprocess.Popen(viewer_cmd)
    time.sleep(5)  # Wait for viewer to connect
    
    try:
        # Find and verify VNC viewer window
        vnc_window = None
        for window in pyautogui.getAllWindows():
            if "VNC" in window.title:
                vnc_window = window
                break
        
        if not vnc_window:
            print("❌ Could not find VNC viewer window")
            return False
        
        # Activate the VNC window
        vnc_window.activate()
        time.sleep(1)
        
        # Test 1: Open a terminal in VNC
        pyautogui.hotkey('ctrl', 'alt', 't')
        time.sleep(3)
        
        # Test 2: Type a command
        pyautogui.typewrite('echo "TurboVNC UI Test Successful" > /tmp/turbovnc_ui_test.log\n')
        time.sleep(2)
        
        # Test 3: Close terminal
        pyautogui.hotkey('alt', 'f4')
        time.sleep(1)
        
        # Verify test results
        # Need to use subprocess to check file on the VNC server
        check_cmd = ["DISPLAY=:1", "cat", "/tmp/turbovnc_ui_test.log"]
        result = subprocess.run(" ".join(check_cmd), shell=True, capture_output=True, text=True)
        
        success = "TurboVNC UI Test Successful" in result.stdout
        print("✅ UI test passed" if success else "❌ UI test failed")
        return success
        
    finally:
        # Cleanup
        viewer.terminate()
        subprocess.run(["/opt/TurboVNC/bin/vncserver", "-kill", ":1"])

if __name__ == "__main__":
    success = run_vnc_ui_test()
    sys.exit(0 if success else 1) 