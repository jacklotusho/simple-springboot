#!/bin/bash

# Spring Boot Background Runner Script
# This script starts the Spring Boot application in the background

echo "=========================================="
echo "  Spring Boot Background Runner          "
echo "=========================================="
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null
then
    echo "❌ Error: Maven is not installed or not in PATH"
    echo "Please install Maven first: https://maven.apache.org/install.html"
    exit 1
fi

# Check if Java is installed
if ! command -v java &> /dev/null
then
    echo "❌ Error: Java is not installed or not in PATH"
    echo "Please install Java 17 or higher"
    exit 1
fi

# Define log file and PID file
LOG_FILE="application.log"
PID_FILE="application.pid"

# Check if application is already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "⚠️  Application is already running with PID: $PID"
        echo "Use ./stop-background.sh to stop it first"
        exit 1
    else
        echo "Removing stale PID file..."
        rm "$PID_FILE"
    fi
fi

echo "✓ Building the application..."
mvn clean package -DskipTests > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Run 'mvn clean package' to see errors."
    exit 1
fi

echo "✓ Build successful!"
echo ""
echo "Starting Spring Boot application in background..."

# Start the application in background
nohup java -jar target/simple-springboot-1.0.0.jar > "$LOG_FILE" 2>&1 &

# Save the PID
echo $! > "$PID_FILE"

echo "✓ Application started in background"
echo "   PID: $(cat $PID_FILE)"
echo "   Log file: $LOG_FILE"
echo "   URL: http://localhost:29600"
echo ""
echo "Commands:"
echo "  - View logs: tail -f $LOG_FILE"
echo "  - Stop app: ./stop-background.sh"
echo "  - Check status: ./status-background.sh"
echo "=========================================="
