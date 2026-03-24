const express = require("express");
const router = express.Router();
const { videoWebhookDone } = require("../controllers/videoJobController");

// POST /api/v1/webhook/video-done — n8n callback sau khi generate xong
router.post("/video-done", videoWebhookDone);

module.exports = router;
