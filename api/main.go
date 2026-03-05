package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Task represents a todo task
type Task struct {
	ID        string `json:"id"`
	Title     string `json:"title" binding:"required,min=1,max=255"`
	Completed bool   `json:"completed"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// TaskRequest represents the request body for creating/updating tasks
type TaskRequest struct {
	Title     string `json:"title" binding:"required,min=1,max=255"`
	Completed bool   `json:"completed"`
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on environment variables")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("pgxpool.New: %v", err)
	}
	defer pool.Close()

	// Optional: fail fast if DB is unreachable at startup.
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("db ping: %v", err)
	}

	// Initialize database schema
	if err := initDB(ctx, pool); err != nil {
		log.Fatalf("failed to initialize database: %v", err)
	}

	r := gin.New()
	r.Use(gin.Recovery())

	// API Routes
	r.GET("/tasks", getTasks(pool))
	r.POST("/tasks", createTask(pool))
	r.PUT("/tasks/:id", updateTask(pool))
	r.DELETE("/tasks/:id", deleteTask(pool))

	srv := &http.Server{
		Addr:    ":8080",
		Handler: r,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-ctx.Done() // wait for SIGINT/SIGTERM
	log.Println("shutdown: signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Stop accepting new connections, wait for in-flight requests (up to timeout).
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("shutdown: %v", err)
	}
	// pool.Close() runs via defer.
}

// initDB creates the tasks table if it doesn't exist
func initDB(ctx context.Context, pool *pgxpool.Pool) error {
	createTableSQL := `
		CREATE TABLE IF NOT EXISTS tasks (
			id SERIAL PRIMARY KEY,
			title VARCHAR(255) NOT NULL,
			completed BOOLEAN DEFAULT FALSE,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
		);

		CREATE OR REPLACE FUNCTION update_updated_at_column()
		RETURNS TRIGGER AS $$
		BEGIN
			NEW.updated_at = CURRENT_TIMESTAMP;
			RETURN NEW;
		END;
		$$ language 'plpgsql';

		DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
		CREATE TRIGGER update_tasks_updated_at
			BEFORE UPDATE ON tasks
			FOR EACH ROW
			EXECUTE FUNCTION update_updated_at_column();
	`

	_, err := pool.Exec(ctx, createTableSQL)
	return err
}

// getTasks retrieves all tasks
func getTasks(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		
		rows, err := pool.Query(ctx, `
			SELECT id::text, title, completed, created_at, updated_at
			FROM tasks
			ORDER BY created_at DESC
		`)
		if err != nil {
			log.Printf("getTasks query error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve tasks"})
			return
		}
		defer rows.Close()

		var tasks []Task
		for rows.Next() {
			var task Task
			if err := rows.Scan(&task.ID, &task.Title, &task.Completed, &task.CreatedAt, &task.UpdatedAt); err != nil {
				log.Printf("getTasks scan error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse task data"})
				return
			}
			tasks = append(tasks, task)
		}

		if err := rows.Err(); err != nil {
			log.Printf("getTasks rows error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve tasks"})
			return
		}

		c.JSON(http.StatusOK, tasks)
	}
}

// createTask creates a new task
func createTask(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req TaskRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
			return
		}

		ctx := c.Request.Context()
		
		var task Task
		err := pool.QueryRow(ctx, `
			INSERT INTO tasks (title, completed)
			VALUES ($1, $2)
			RETURNING id::text, title, completed, created_at, updated_at
		`, req.Title, req.Completed).Scan(
			&task.ID, &task.Title, &task.Completed, &task.CreatedAt, &task.UpdatedAt,
		)
		if err != nil {
			log.Printf("createTask insert error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create task"})
			return
		}

		c.JSON(http.StatusCreated, task)
	}
}

// updateTask updates an existing task
func updateTask(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Task ID is required"})
			return
		}

		var req TaskRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
			return
		}

		ctx := c.Request.Context()
		
		var task Task
		err := pool.QueryRow(ctx, `
			UPDATE tasks
			SET title = $1, completed = $2
			WHERE id = $3
			RETURNING id::text, title, completed, created_at, updated_at
		`, req.Title, req.Completed, id).Scan(
			&task.ID, &task.Title, &task.Completed, &task.CreatedAt, &task.UpdatedAt,
		)
		if err != nil {
			log.Printf("updateTask update error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update task"})
			return
		}

		c.JSON(http.StatusOK, task)
	}
}

// deleteTask deletes a task
func deleteTask(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Task ID is required"})
			return
		}

		ctx := c.Request.Context()
		
		// First check if the task exists
		var exists bool
		err := pool.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM tasks WHERE id = $1)", id).Scan(&exists)
		if err != nil {
			log.Printf("deleteTask check exists error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check task existence"})
			return
		}

		if !exists {
			c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
			return
		}

		_, err = pool.Exec(ctx, "DELETE FROM tasks WHERE id = $1", id)
		if err != nil {
			log.Printf("deleteTask delete error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete task"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Task deleted successfully"})
	}
}
