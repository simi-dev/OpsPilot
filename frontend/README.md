# OpsPilot Tasks - Simple JavaScript Todo App

A lightweight todo application built with vanilla JavaScript and Node.js. No build tools or complex dependencies required!

## Features

- Add new tasks
- Mark tasks as completed/incomplete
- Delete tasks
- Responsive design
- Dark mode toggle
- In-memory data storage

## How to Run

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Start the server:
   ```bash
   node server.js
   ```

3. Open your browser and visit:
   ```
   http://localhost:3000
   ```

## Project Structure

```
frontend/
├── index.html     # Main HTML file with CSS and JavaScript
├── server.js      # Node.js server with API endpoints
└── README.md      # This file
```

## API Endpoints

The application uses a simple Node.js server with the following endpoints:

- `GET /api/tasks` - Get all tasks
- `POST /api/tasks` - Create a new task
- `PUT /api/tasks/:id` - Update a task (toggle completion)
- `DELETE /api/tasks/:id` - Delete a task

## No Installation Required

This application requires only Node.js (version 12+ recommended) to run the server. The frontend is pure HTML, CSS, and JavaScript that runs directly in the browser.

## Browser Compatibility

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## Notes

- Data is stored in memory only (will be lost when the server restarts)
- For production use, you would want to connect to a proper database
- CORS headers are enabled for cross-origin requests
- The server runs on port 3000 by default (configurable via PORT environment variable)