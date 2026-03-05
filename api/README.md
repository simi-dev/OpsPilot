# OpsPilot API

A Go-based REST API for managing todo tasks with PostgreSQL database integration.

## Features

- **CRUD Operations**: Create, Read, Update, Delete tasks
- **PostgreSQL Integration**: Persistent data storage
- **Input Validation**: Request validation using Gin binding tags
- **Error Handling**: Comprehensive error handling and logging
- **Database Schema**: Automatic table creation and management
- **Context Support**: Proper request cancellation and timeout handling

## Prerequisites

- Go 1.25.0 or later
- PostgreSQL database
- `pgx` driver for PostgreSQL

## Installation

### 1. Install Dependencies

```bash
go mod download
go mod tidy
```

### 2. Database Setup

#### Option A: Local PostgreSQL Installation

1. Install PostgreSQL on your system
2. Create a database:
   ```sql
   CREATE DATABASE opspilot;
   ```

3. Create a user (optional):
   ```sql
   CREATE USER opspilot WITH PASSWORD 'devops';
   GRANT ALL PRIVILEGES ON DATABASE opspilot TO opspilot;
   ```

#### Option B: Docker PostgreSQL

```bash
docker run --name opspilot-postgres \
  -e POSTGRES_DB=opspilot \
  -e POSTGRES_USER=opspilot \
  -e POSTGRES_PASSWORD=devops \
  -p 5432:5432 \
  -d postgres:latest
```

### 3. Environment Configuration

Copy the `.env.example` file to `.env` and update with your database connection details:

```bash
cp .env .env.local
```

Edit `.env.local` with your PostgreSQL connection string:

```env
DATABASE_URL='postgresql://username:password@localhost:5432/database_name?sslmode=disable'
```

### 4. Run the Application

```bash
go run main.go
```

The API will start on `http://localhost:8080`

## API Endpoints

### Get All Tasks

```bash
curl -X GET http://localhost:8080/tasks
```

**Response:**
```json
[
  {
    "id": "1",
    "title": "Setup development environment",
    "completed": false,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T10:00:00Z"
  }
]
```

### Create a Task

```bash
curl -X POST http://localhost:8080/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Go programming",
    "completed": false
  }'
```

**Response:**
```json
{
  "id": "2",
  "title": "Learn Go programming",
  "completed": false,
  "created_at": "2024-01-01T10:30:00Z",
  "updated_at": "2024-01-01T10:30:00Z"
}
```

### Update a Task

```bash
curl -X PUT http://localhost:8080/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Setup development environment (completed)",
    "completed": true
  }'
```

**Response:**
```json
{
  "id": "1",
  "title": "Setup development environment (completed)",
  "completed": true,
  "created_at": "2024-01-01T10:00:00Z",
  "updated_at": "2024-01-01T10:45:00Z"
}
```

### Delete a Task

```bash
curl -X DELETE http://localhost:8080/tasks/1
```

**Response:**
```json
{
  "message": "Task deleted successfully"
}
```

## Error Responses

### Validation Error

```bash
curl -X POST http://localhost:8080/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": ""}'
```

**Response (400 Bad Request):**
```json
{
  "error": "Invalid request body",
  "details": "Key: 'TaskRequest.Title' Error:Field validation for 'Title' failed on the 'min' tag"
}
```

### Task Not Found

```bash
curl -X GET http://localhost:8080/tasks/999
```

**Response (404 Not Found):**
```json
{
  "error": "Task not found"
}
```

### Server Error

```bash
curl -X GET http://localhost:8080/tasks
```

**Response (500 Internal Server Error):**
```json
{
  "error": "Failed to retrieve tasks"
}
```

## Database Schema

The API automatically creates the following table structure:

```sql
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Automatic Features

- **Auto-incrementing IDs**: Tasks get unique serial IDs
- **Timestamps**: Automatic creation and update timestamps
- **Update Trigger**: PostgreSQL trigger automatically updates `updated_at` field
- **Validation**: Title length validation (1-255 characters)

## Development

### Build the Application

```bash
go build -o opspilot-api
```

### Run Tests

```bash
go test ./...
```

### Code Formatting

```bash
go fmt ./...
```

### Linting

```bash
go vet ./...
```

## Production Deployment

### Environment Variables

Set the following environment variables in production:

- `DATABASE_URL`: PostgreSQL connection string
- `PORT`: Server port (default: 8080)

### SSL Configuration

For production PostgreSQL connections, update the connection string:

```env
DATABASE_URL='postgresql://user:pass@host:5432/db?sslmode=require'
```

### Health Check

The API includes a basic health check endpoint:

```bash
curl http://localhost:8080/health
```

## Monitoring and Logging

The application logs all database operations and errors. For production monitoring:

1. **Database Connection**: Monitor PostgreSQL connection pool
2. **Request Logging**: All requests are logged with context
3. **Error Tracking**: Database errors are logged with details
4. **Performance**: Use PostgreSQL query monitoring tools

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL is running
   - Verify connection string in `.env`
   - Ensure database exists and user has permissions

2. **Table Creation Failed**
   - Check database user permissions
   - Verify PostgreSQL version compatibility

3. **Port Already in Use**
   - Change port in `main.go` or use `PORT` environment variable

### Debug Mode

Enable debug logging by modifying the Gin engine:

```go
r := gin.Default() // Instead of gin.New()
```

## Security Considerations

- **Input Validation**: All inputs are validated
- **SQL Injection**: Using parameterized queries prevents SQL injection
- **CORS**: API allows all origins (configure for production)
- **Authentication**: Not included (add JWT/auth middleware as needed)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License.