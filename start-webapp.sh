#!/bin/bash

# Spring Boot JAR Runner Script
# This script builds and runs the Spring Boot application from the JAR file

echo "=========================================="
echo "  Spring Boot JAR Runner                 "
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

echo "✓ Building the application..."
echo ""

# Build the project
mvn clean package -DskipTests

# Check if build was successful
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi

echo ""
echo "✓ Build successful!"
echo ""
echo "Starting Spring Boot application from JAR..."
echo "The application will be available at: http://localhost:29600"
echo ""
echo "Press Ctrl+C to stop the application"
echo "=========================================="
echo ""

# Run the JAR file
java -jar target/simple-springboot-1.0.0.jar
