#!/bin/bash

# Spring Boot Background Stopper Script
# This script stops the Spring Boot application running in the background

echo "=========================================="
echo "  Spring Boot Background Stopper         "
echo "=========================================="
echo ""

PID_FILE="application.pid"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "⚠️  No PID file found. Application may not be running."
    exit 1
fi

# Read the PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️  Process with PID $PID is not running."
    echo "Removing stale PID file..."
    rm "$PID_FILE"
    exit 1
fi

echo "Stopping application (PID: $PID)..."

# Stop the process
kill "$PID"

# Wait for process to stop
for i in {1..10}; do
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo "✓ Application stopped successfully"
        rm "$PID_FILE"
        echo "=========================================="
        exit 0
    fi
    sleep 1
done

# Force kill if still running
echo "⚠️  Application did not stop gracefully. Force killing..."
kill -9 "$PID"
rm "$PID_FILE"
echo "✓ Application force stopped"
echo "=========================================="
