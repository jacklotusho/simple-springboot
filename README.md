# Simple Spring Boot Web App

A simple web application built with Spring Boot 3.5.10 that demonstrates basic REST API endpoints and web page rendering using Thymeleaf.

## Features

- 🏠 Home page with interactive UI
- 🔌 RESTful API endpoints
- 🎨 Modern, responsive design
- 🔄 Hot reload with Spring Boot DevTools
- 📝 Thymeleaf template engine

## Prerequisites

- Java 17 or higher
- Maven 3.6 or higher

## Project Structure

```
simple-springboot/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/simpleapp/
│   │   │       ├── SimpleSpringBootApplication.java
│   │   │       └── controller/
│   │   │           └── HomeController.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── templates/
│   │           └── index.html
├── pom.xml
└── README.md
```

## How to Run

### Option 1: Background Mode (Recommended for Production)

Run the application in the background as a daemon process:

```bash
./start-background.sh
```

This will:
- Build the application
- Start it in the background
- Create a PID file for process management
- Log output to `application.log`

**Management Commands:**
```bash
# Check application status
./status-background.sh

# Stop the application
./stop-background.sh

# View logs in real-time
tail -f application.log
```

### Option 2: Using the JAR Runner Script

```bash
./start-webapp.sh
```

This script will:
- Check if Maven and Java are installed
- Build the application (mvn clean package)
- Run the application from the JAR file using `java -jar`
- Show the application URL

### Option 3: Using the Development Run Script

```bash
./run-app.sh
```

This script will:
- Check if Maven and Java are installed
- Display version information
- Start the Spring Boot application with hot reload
- Show the application URL

### Option 4: Using Maven Directly

```bash
mvn spring-boot:run
```

### Option 5: Build and Run JAR Manually

```bash
# Build the project
mvn clean package

# Run the JAR file
java -jar target/simple-springboot-1.0.0.jar
```

## Accessing the Application

Once the application is running, open your browser and navigate to:

- **Home Page**: http://localhost:29600/
- **API Hello Endpoint**: http://localhost:29600/api/hello?name=YourName
- **API Info Endpoint**: http://localhost:29600/api/info

## API Endpoints

### GET /api/hello

Returns a personalized greeting message.

**Parameters:**
- `name` (optional, default: "World") - The name to greet

**Example:**
```bash
curl http://localhost:29600/api/hello?name=SpringBoot
```

**Response:**
```
Hello, SpringBoot!
```

### GET /api/info

Returns application information in JSON format.

**Example:**
```bash
curl http://localhost:29600/api/info
```

**Response:**
```json
{
  "name": "Simple Spring Boot App",
  "version": "1.0.0",
  "description": "A simple web application"
}
```

## Technologies Used

- **Spring Boot 3.5.10** - Application framework
- **Spring Web** - REST API support
- **Thymeleaf** - Template engine for HTML rendering
- **Spring Boot DevTools** - Hot reload during development
- **Maven** - Build and dependency management

## Configuration

The application can be configured via `src/main/resources/application.yml`:

- `server.port` - Server port (default: 29600)
- `spring.application.name` - Application name
- Thymeleaf and logging configurations

## Development

To enable hot reload during development, Spring Boot DevTools is included. Any changes to Java files or templates will automatically restart the application.

## License

This project is open source and available for educational purposes.