#!/usr/bin/env python3
import os
import subprocess
import time
import statistics
import argparse

def measure_latency(operations=10):
    """Measure TurboVNC latency by performing X11 operations"""
    results = []
    
    # Start VNC server
    subprocess.run(["/opt/TurboVNC/bin/vncserver", ":1", "-geometry", "1024x768"])
    viewer_cmd = ["/opt/TurboVNC/bin/vncviewer", "localhost:1"]
    
    # Give server time to start
    time.sleep(3)
    
    # Start viewer headlessly
    viewer = subprocess.Popen(viewer_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(3)
    
    try:
        # Run test operations
        for i in range(operations):
            start_time = time.time()
            
            # Create a window, perform an operation, and close it
            proc = subprocess.run(
                ["DISPLAY=:1", "xterm", "-e", "echo 'Test'; sleep 0.5"],
                shell=True, capture_output=True
            )
            
            end_time = time.time()
            if proc.returncode == 0:
                results.append(end_time - start_time)
    
    finally:
        # Cleanup
        viewer.terminate()
        subprocess.run(["/opt/TurboVNC/bin/vncserver", "-kill", ":1"])
    
    # Process results
    if results:
        return {
            "min": min(results),
            "max": max(results),
            "avg": statistics.mean(results),
            "median": statistics.median(results)
        }
    else:
        return {"error": "No successful operations recorded"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TurboVNC performance test")
    parser.add_argument("--operations", type=int, default=10, help="Number of operations to perform")
    args = parser.parse_args()
    
    print(f"Testing TurboVNC performance...")
    results = measure_latency(args.operations)
    print(f"Results: {results}") 