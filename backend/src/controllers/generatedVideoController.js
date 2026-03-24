const GeneratedVideo = require("../data/generatedVideoModel");
const mongoose = require("mongoose");

const isMongoAvailable = () => mongoose.connection.readyState === 1;

/**
 * GET /api/v1/generated-videos
 * Lấy danh sách video đã generate, sort mới nhất trước.
 */
async function listGeneratedVideos(req, res) {
  if (!isMongoAvailable()) {
    return res
      .status(503)
      .json({ error: "Database not available", videos: [] });
  }

  try {
    const limit = Math.min(parseInt(req.query.limit) || 50, 200);
    const skip = parseInt(req.query.skip) || 0;

    const [videos, total] = await Promise.all([
      GeneratedVideo.find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      GeneratedVideo.countDocuments(),
    ]);

    return res.json({ total, videos });
  } catch (err) {
    console.error("❌ listGeneratedVideos error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}

/**
 * DELETE /api/v1/generated-videos/:id
 * Xoá một video khỏi DB.
 */
async function deleteGeneratedVideo(req, res) {
  if (!isMongoAvailable()) {
    return res.status(503).json({ error: "Database not available" });
  }

  try {
    const result = await GeneratedVideo.findByIdAndDelete(req.params.id);
    if (!result) {
      return res.status(404).json({ error: "Video not found" });
    }
    return res.json({ ok: true });
  } catch (err) {
    console.error("❌ deleteGeneratedVideo error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}

module.exports = { listGeneratedVideos, deleteGeneratedVideo };
