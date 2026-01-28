#!/usr/bin/env python3
"""
ClamAV Stats Web Server for Homepage Integration
Exposes ClamAV scan statistics via HTTP API
"""

import json
import subprocess
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

class ClamAVStatsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/status' or parsed_path.path == '/':
            try:
                # Execute Python stats script
                result = subprocess.run(['python3', '/app/clamav-stats.py'], 
                                      capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0:
                    # Parse JSON to validate
                    stats = json.loads(result.stdout)
                    
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(result.stdout.encode('utf-8'))
                else:
                    self.send_error(500, f"Script execution failed: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                self.send_error(504, "Script timeout")
            except json.JSONDecodeError:
                self.send_error(500, "Invalid JSON response")
            except Exception as e:
                self.send_error(500, f"Internal error: {str(e)}")
                
        elif parsed_path.path == '/health':
            # Simple health check
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {"status": "ok", "service": "clamav-stats"}
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        else:
            self.send_error(404, "Not Found")
    
    def log_message(self, format, *args):
        # Reduce logging noise
        return

if __name__ == '__main__':
    PORT = 8080
    server = HTTPServer(('0.0.0.0', PORT), ClamAVStatsHandler)
    print(f"🌐 ClamAV Stats Server running on port {PORT}")
    print("📊 Endpoints: /status, /health")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("🛑 Server stopped")
        server.shutdown()