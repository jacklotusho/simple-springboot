#!/bin/bash

# Simple Spring Boot Application Runner Script
# This script provides an easy way to run the Spring Boot application

echo "=========================================="
echo "  Simple Spring Boot Application Runner  "
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

# Display Java version
echo "✓ Java version:"
java -version 2>&1 | head -n 1
echo ""

# Display Maven version
echo "✓ Maven version:"
mvn -version | head -n 1
echo ""

echo "Starting Spring Boot application..."
echo "The application will be available at: http://localhost:29600"
echo ""
echo "Press Ctrl+C to stop the application"
echo "=========================================="
echo ""

# Run the Spring Boot application
mvn spring-boot:run
