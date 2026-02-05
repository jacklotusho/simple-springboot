#!/bin/bash

# Spring Boot Background Status Script
# This script checks the status of the Spring Boot application

echo "=========================================="
echo "  Spring Boot Application Status         "
echo "=========================================="
echo ""

PID_FILE="application.pid"
LOG_FILE="application.log"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "Status: ❌ NOT RUNNING"
    echo "No PID file found."
    echo ""
    echo "Start the application with: ./start-background.sh"
    echo "=========================================="
    exit 1
fi

# Read the PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ps -p "$PID" > /dev/null 2>&1; then
    echo "Status: ✓ RUNNING"
    echo "PID: $PID"
    echo "URL: http://localhost:29600"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Process details:"
    ps -p "$PID" -o pid,ppid,cmd,%cpu,%mem,etime
    echo ""
    echo "Recent logs (last 10 lines):"
    echo "----------------------------"
    if [ -f "$LOG_FILE" ]; then
        tail -10 "$LOG_FILE"
    else
        echo "No log file found"
    fi
    echo "----------------------------"
    echo ""
    echo "Commands:"
    echo "  - View full logs: tail -f $LOG_FILE"
    echo "  - Stop app: ./stop-background.sh"
else
    echo "Status: ❌ NOT RUNNING"
    echo "PID file exists but process $PID is not running."
    echo "Removing stale PID file..."
    rm "$PID_FILE"
    echo ""
    echo "Start the application with: ./start-background.sh"
fi

echo "=========================================="
