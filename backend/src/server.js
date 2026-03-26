const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const compression = require("compression");
const path = require("path");
require("dotenv").config();

const { connectDB } = require("./data/db");

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
// Configure helmet with CORS-friendly settings
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
    crossOriginOpenerPolicy: { policy: "same-origin-allow-popups" },
  }),
);

// Enable CORS for all origins in development
app.use(
  cors({
    origin: "*", // Accept all origins for development
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true,
  }),
);

app.use(compression()); // Compress responses
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(morgan("dev")); // Logging

// Serve static files from uploads directory
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

// Routes
const apiRoutes = require("./routes");
app.use("/api", apiRoutes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || "development",
  });
});

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Video Template API Server",
    version: "1.0.0",
    endpoints: {
      health: "/health",
      api: "/api/v1",
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: "Not Found",
    message: `Route ${req.method} ${req.url} not found`,
    timestamp: new Date().toISOString(),
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error("Error:", err);

  res.status(err.status || 500).json({
    error: err.name || "Internal Server Error",
    message: err.message || "Something went wrong",
    ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
  });
});

// Kết nối MongoDB khi khởi động
connectDB();

// Export app cho Vercel serverless
module.exports = app;

// Start server chỉ khi chạy local (không phải serverless)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`
  🚀 Server is running!
  
  📍 Local:            http://localhost:${PORT}
  🏥 Health Check:     http://localhost:${PORT}/health
  📡 API Endpoint:     http://localhost:${PORT}/api/v1
  🌍 Environment:      ${process.env.NODE_ENV || "development"}
  
  Press CTRL+C to stop
  `);
  });
}

