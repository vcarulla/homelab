#!/usr/bin/env python3
"""
ClamAV Log Parser for Homepage Integration
Parses ClamAV log files and returns JSON statistics
"""

import json
import os
import glob
import re
from datetime import datetime, timezone, timedelta

def parse_clamav_logs():
    """Parse latest ClamAV log file and return statistics"""
    
    log_dir = "/var/log/clamav-scans"
    
    try:
        # Find latest log file
        log_files = glob.glob(os.path.join(log_dir, "clamav-scan-*.log"))
        if not log_files:
            return {
                "threats": "🔴 Sin datos",
                "age": "🔴 --",
                "infected_files": -1,
                "total_errors": -1,
                "scan_sections": 0,
                "scan_duration": "unknown",
                "log_file": "none"
            }
        
        latest_log = max(log_files, key=os.path.getmtime)
        log_filename = os.path.basename(latest_log)
        
        # Extract timestamp from filename: clamav-scan-20250910_1630.log
        timestamp_match = re.search(r'(\d{8})_(\d{4})', log_filename)
        if timestamp_match:
            date_str = timestamp_match.group(1)  # 20250910
            time_str = timestamp_match.group(2)  # 1630
            # Format as readable: "10/09 16:30"
            day = date_str[6:8]
            month = date_str[4:6] 
            hour = time_str[:2]
            minute = time_str[2:4]
            scan_time = f"{day}/{month} {hour}:{minute}"
        else:
            scan_time = "unknown"
        
        # Parse log file
        with open(latest_log, 'r') as f:
            content = f.read()
        
        # Extract statistics
        infected_files = 0
        total_errors = 0
        scan_duration = "0s"
        scan_sections = content.count("SCAN SUMMARY")
        
        # Find infected files count
        infected_match = re.search(r'Archivos infectados encontrados:\s*(\d+)', content)
        if infected_match:
            infected_files = int(infected_match.group(1))
        
        # Count errors
        error_matches = re.findall(r'Total errors:\s*(\d+)', content)
        if error_matches:
            total_errors = sum(int(x) for x in error_matches)
        
        # Find scan duration
        time_matches = re.findall(r'Time:\s*([\d.]+)\s*sec', content)
        if time_matches:
            total_time = sum(float(x) for x in time_matches)
            scan_duration = f"{total_time:.3f}s"
        
        # Calculate age (using Argentina timezone UTC-3)
        try:
            if timestamp_match:
                # Parse log time as Argentina time (UTC-3)
                log_datetime = datetime.strptime(f"{date_str}{time_str}", "%Y%m%d%H%M")
                log_datetime = log_datetime.replace(tzinfo=timezone(timedelta(hours=-3)))
                
                # Current time in Argentina timezone  
                now_arg = datetime.now(timezone(timedelta(hours=-3)))
                age_hours = int((now_arg - log_datetime).total_seconds() / 3600)
            else:
                age_hours = 999
        except:
            age_hours = 999
        
        # Status basado SOLO en amenazas
        if infected_files > 0:
            threat_status = "🚨 INFECTADO"
        else:
            threat_status = "✅ Limpio"
        
        # Status de antigüedad con emojis
        if age_hours < 2:
            age_status = f"🟢 {age_hours}h"
        elif age_hours < 6:
            age_status = f"🟡 {age_hours}h" 
        else:
            age_status = f"🔴 {age_hours}h"
        
        return {
            "threats": threat_status,
            "age": age_status,
            "infected_files": infected_files,
            "total_errors": total_errors,
            "scan_sections": scan_sections,
            "scan_duration": scan_duration,
            "log_file": log_filename
        }
        
    except Exception as e:
        return {
            "threats": "🔴 Error",
            "age": "🔴 --",
            "infected_files": -1,
            "total_errors": -1,
            "scan_sections": 0,
            "scan_duration": "error",
            "log_file": str(e)
        }

if __name__ == "__main__":
    stats = parse_clamav_logs()
    print(json.dumps(stats, indent=2))