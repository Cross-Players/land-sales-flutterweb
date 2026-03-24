const express = require("express");
const router = express.Router();
const {
  listGeneratedVideos,
  deleteGeneratedVideo,
} = require("../controllers/generatedVideoController");

// GET  /api/v1/generated-videos        — danh sách video đã generate
// DELETE /api/v1/generated-videos/:id  — xoá video
router.get("/", listGeneratedVideos);
router.delete("/:id", deleteGeneratedVideo);

module.exports = router;
