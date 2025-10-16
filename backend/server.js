const express = require("express");
const cors = require("cors");
require("dotenv").config();

const logger = require("./utils/logger");
const userRoutes = require("./routes/userRoutes");
const taskRoutes = require("./routes/taskRoutes");
const submissionRoutes = require("./routes/submissionRoutes");
const portfolioRoutes = require("./routes/portfolioRoutes");
const edupointsRoutes = require("./routes/edupointsRoutes");

const app = express();

// Log application startup
logger.info("EduBridge API starting up", {
  nodeVersion: process.version,
  environment: process.env.NODE_ENV || "development",
  port: process.env.PORT || 5050,
});

// Middleware
app.use(cors());
logger.debug("CORS middleware enabled");

app.use(express.json());
logger.debug("JSON body parser middleware enabled");

// Request logging middleware
app.use(logger.logRequest);

// Helper functions
function success(res, data) {
  logger.debug("Sending success response", {
    data: typeof data === "object" ? Object.keys(data || {}) : "primitive",
  });
  return res.status(200).json({ success: true, data });
}

// Health check endpoint
app.get("/", (req, res) => {
  logger.info("Health check requested", { ip: req.ip });
  success(res, {
    service: "EduBridge API",
    status: "running",
    timestamp: new Date().toISOString(),
  });
});

// Log route registration
logger.debug("Registering routes...");
app.use(
  "/users",
  (req, res, next) => {
    logger.debug("User routes accessed", { method: req.method, path: req.path });
    next();
  },
  userRoutes
);

app.use(
  "/tasks",
  (req, res, next) => {
    logger.debug("Task routes accessed", { method: req.method, path: req.path });
    next();
  },
  taskRoutes
);

app.use(
  "/submissions",
  (req, res, next) => {
    logger.debug("Submission routes accessed", { method: req.method, path: req.path });
    next();
  },
  submissionRoutes
);

app.use(
  "/portfolio",
  (req, res, next) => {
    logger.debug("Portfolio routes accessed", { method: req.method, path: req.path });
    next();
  },
  portfolioRoutes
);

app.use(
  "/edupoints",
  (req, res, next) => {
    logger.debug("EduPoints routes accessed", { method: req.method, path: req.path });
    next();
  },
  edupointsRoutes
);

logger.info("All routes registered successfully");

// Global error handler
app.use((error, req, res, next) => {
  logger.error("Unhandled error", {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
  });
  res.status(500).json({ success: false, error: "Internal server error" });
});

// 404 handler
app.use((req, res) => {
  logger.warn("Route not found", {
    method: req.method,
    url: req.url,
    ip: req.ip,
  });
  res.status(404).json({ success: false, error: "Route not found" });
});

const PORT = process.env.PORT || 5050;

// Start server
const server = app.listen(PORT, () => {
  logger.info("EduBridge API server started successfully", {
    port: PORT,
    environment: process.env.NODE_ENV || "development",
    supabaseUrl: process.env.SUPABASE_URL ? "configured" : "missing",
    supabaseKey: process.env.SUPABASE_SERVICE_ROLE_KEY ? "configured" : "missing",
  });
});

// Graceful shutdown handling
process.on("SIGTERM", () => {
  logger.info("SIGTERM received, shutting down gracefully");
  server.close(() => {
    logger.info("Server closed successfully");
    process.exit(0);
  });
});

process.on("SIGINT", () => {
  logger.info("SIGINT received, shutting down gracefully");
  server.close(() => {
    logger.info("Server closed successfully");
    process.exit(0);
  });
});
