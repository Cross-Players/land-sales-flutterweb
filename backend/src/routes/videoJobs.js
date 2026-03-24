const express = require("express");
const router = express.Router();
const {
  createVideoJob,
  triggerN8nJob,
  getVideoJob,
  streamVideoJob,
} = require("../controllers/videoJobController");

// POST   /api/v1/video-jobs                    — Tạo job mới
router.post("/", createVideoJob);

// POST   /api/v1/video-jobs/:jobId/trigger     — Proxy trigger n8n (tránh CORS)
router.post("/:jobId/trigger", triggerN8nJob);

// GET    /api/v1/video-jobs/:jobId             — Lấy status job
router.get("/:jobId", getVideoJob);

// GET    /api/v1/video-jobs/:jobId/stream      — SSE stream
router.get("/:jobId/stream", streamVideoJob);

module.exports = router;
