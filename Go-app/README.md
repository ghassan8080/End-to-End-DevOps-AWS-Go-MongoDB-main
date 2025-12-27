# Go Survey Application

A lightweight survey application built with Go that provides REST API endpoints for collecting and storing survey responses in MongoDB.

## Table of Contents

- [Application Overview](#application-overview)
- [Environment Variables](#environment-variables)
- [Build & Run Instructions](#build--run-instructions)
- [API Documentation](#api-documentation)

---

## Application Overview

The Go Survey Application is a simple REST API that allows users to submit survey responses. It consists of two main endpoints:

1. **GET /**: Returns the survey question
2. **POST /**: Accepts survey responses and stores them in MongoDB

### Tech Stack

- **Language**: Go 1.21
- **Web Framework**: Gorilla Mux
- **Database**: MongoDB
- **Container**: Docker

---

## Environment Variables

The application can be configured using the following environment variables:

| Variable | Description | Default Value | Required |
|----------|-------------|---------------|----------|
| `SERVER_PORT` | Port on which the application listens | `8080` | No |
| `MONGO_URI` | MongoDB connection URI | `mongodb://localhost:27017` | Yes |

### Example Environment Configuration

```bash
# For local development
export SERVER_PORT=8080
export MONGO_URI=mongodb://localhost:27017

# For Kubernetes deployment (set in k8s/app.yml)
MONGO_URI: mongodb://mongo-app-service.go-survey.svc:27017
SERVER_PORT: 8080
```

---

## Build & Run Instructions

### Local Development

1. **Install Go dependencies**:
   ```bash
   cd Go-app
   go mod download
   go mod verify
   ```

2. **Set up MongoDB**:
   - Install MongoDB locally or use Docker:
     ```bash
     docker run -d -p 27017:27017 --name mongodb mongo:7.0.11
     ```

3. **Run the application**:
   ```bash
   go run main.go
   ```

4. **Test the application**:
   ```bash
   # Get the survey question
   curl http://localhost:8080/
   
   # Submit a survey response
   curl -X POST http://localhost:8080/ \
     -H "Content-Type: application/json" \
     -d '{"answer1": "Option 1", "answer2": "Option 2", "answer3": "Option 3"}'
   ```

### Docker Build

1. **Build the Docker image**:
   ```bash
   docker build -t go-survey:latest .
   ```

2. **Run the container**:
   ```bash
   docker run -d -p 8080:8080 --name go-survey \
     -e MONGO_URI=mongodb://host.docker.internal:27017 \
     go-survey:latest
   ```

### Docker Compose

1. **Start the application and database**:
   ```bash
   docker-compose up -d
   ```

2. **View logs**:
   ```bash
   docker-compose logs -f
   ```

3. **Stop the application**:
   ```bash
   docker-compose down
   ```

---

## API Documentation

### Get Survey Question

**Endpoint**: `GET /`

**Description**: Returns the current survey question.

**Response**:
```json
"What is your favorite programming language framework?"
```

**Example**:
```bash
curl http://localhost:8080/
```

### Submit Survey Response

**Endpoint**: `POST /`

**Description**: Accepts survey responses and stores them in MongoDB.

**Request Body**:
```json
{
  "answer1": "Option 1",
  "answer2": "Option 2",
  "answer3": "Option 3"
}
```

**Response**:
- **Status Code**: `201 Created`
- **Body**: MongoDB document ID

```json
{
  "_id": "507f1f77bcf86cd799439011"
}
```

**Example**:
```bash
curl -X POST http://localhost:8080/ \
  -H "Content-Type: application/json" \
  -d '{"answer1": "React", "answer2": "Vue", "answer3": "Angular"}'
```

### Error Responses

| Status Code | Description |
|-------------|-------------|
| `400 Bad Request` | Invalid request body |
| `500 Internal Server Error` | Failed to save answer to database |

**Error Response Format**:
```json
{
  "error": "Invalid request body"
}
```

---

## Development Notes

### MongoDB Connection

The application connects to MongoDB using the official MongoDB Go driver. Connection is established on startup and verified with a ping operation to ensure the database is accessible.

### Error Handling

The application implements proper error handling for:
- MongoDB connection failures
- Invalid request bodies
- Database operation failures

All errors are logged with descriptive messages for debugging purposes.

---

## License

This application is part of the End-to-End DevOps project. See the main repository for license information.
