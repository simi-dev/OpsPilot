const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

// In-memory storage for tasks
let tasks = [
    {
        id: '1',
        title: 'Setup development environment',
        completed: false
    },
    {
        id: '2', 
        title: 'Create API endpoints',
        completed: true
    },
    {
        id: '3',
        title: 'Build frontend interface',
        completed: false
    }
];

// Helper function to generate unique ID
function generateId() {
    return Math.random().toString(36).substr(2, 9);
}

// Helper function to set CORS headers
function setCORSHeaders(res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

// Helper function to send JSON response
function sendJSON(res, data, statusCode = 200) {
    setCORSHeaders(res);
    res.setHeader('Content-Type', 'application/json');
    res.statusCode = statusCode;
    res.end(JSON.stringify(data));
}

// Helper function to parse request body
function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });
        req.on('end', () => {
            try {
                resolve(body ? JSON.parse(body) : {});
            } catch (error) {
                reject(error);
            }
        });
    });
}

// API Routes
const routes = {
    // GET /api/tasks - Get all tasks
    'GET /api/tasks': async (req, res) => {
        sendJSON(res, tasks);
    },

    // POST /api/tasks - Create a new task
    'POST /api/tasks': async (req, res) => {
        try {
            const body = await parseBody(req);
            const { title } = body;
            
            if (!title || title.trim() === '') {
                sendJSON(res, { error: 'Title is required' }, 400);
                return;
            }
            
            const newTask = {
                id: generateId(),
                title: title.trim(),
                completed: false
            };
            
            tasks.push(newTask);
            sendJSON(res, newTask, 201);
        } catch (error) {
            sendJSON(res, { error: 'Invalid JSON' }, 400);
        }
    },

    // PUT /api/tasks/:id - Update a task (toggle completion)
    'PUT /api/tasks/:id': async (req, res) => {
        try {
            const urlParts = req.url.split('/');
            const id = urlParts[urlParts.length - 1];
            const body = await parseBody(req);
            const { completed } = body;
            
            if (!id) {
                sendJSON(res, { error: 'Task ID is required' }, 400);
                return;
            }
            
            if (typeof completed !== 'boolean') {
                sendJSON(res, { error: 'Completed status must be boolean' }, 400);
                return;
            }
            
            const taskIndex = tasks.findIndex(t => t.id === id);
            if (taskIndex === -1) {
                sendJSON(res, { error: 'Task not found' }, 404);
                return;
            }
            
            tasks[taskIndex].completed = completed;
            sendJSON(res, tasks[taskIndex]);
        } catch (error) {
            sendJSON(res, { error: 'Invalid JSON' }, 400);
        }
    },

    // DELETE /api/tasks/:id - Delete a task
    'DELETE /api/tasks/:id': async (req, res) => {
        const urlParts = req.url.split('/');
        const id = urlParts[urlParts.length - 1];
        
        if (!id) {
            sendJSON(res, { error: 'Task ID is required' }, 400);
            return;
        }
        
        const taskIndex = tasks.findIndex(t => t.id === id);
        if (taskIndex === -1) {
            sendJSON(res, { error: 'Task not found' }, 404);
            return;
        }
        
        const deletedTask = tasks.splice(taskIndex, 1)[0];
        sendJSON(res, { message: 'Task deleted successfully', task: deletedTask });
    }
};

// Create HTTP server
const server = http.createServer(async (req, res) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        setCORSHeaders(res);
        res.statusCode = 200;
        res.end();
        return;
    }

    // Serve static files (HTML, CSS, JS)
    if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
        const filePath = path.join(__dirname, 'index.html');
        fs.readFile(filePath, (err, data) => {
            if (err) {
                res.statusCode = 500;
                res.end('Internal Server Error');
                return;
            }
            res.setHeader('Content-Type', 'text/html');
            res.end(data);
        });
        return;
    }

    // Handle API routes
    const routeKey = `${req.method} ${req.url}`;
    const route = routes[routeKey];
    
    if (route) {
        try {
            await route(req, res);
        } catch (error) {
            console.error('Route error:', error);
            sendJSON(res, { error: 'Internal Server Error' }, 500);
        }
    } else {
        // 404 Not Found
        setCORSHeaders(res);
        res.statusCode = 404;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ error: 'Not Found' }));
    }
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log('Open your browser and visit the URL above to use the todo app');
});