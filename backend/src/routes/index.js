const express = require("express");
const router = express.Router();

// Import route modules
const videoTemplateRoutes = require("./videoTemplates");
const videoJobRoutes = require("./videoJobs");
const webhookRoutes = require("./webhook");
const generatedVideoRoutes = require("./generatedVideos");
const uploadRoutes = require("./upload");

// API version 1
const v1Router = express.Router();

// Mount routes
v1Router.use("/video-templates", videoTemplateRoutes);
v1Router.use("/video-jobs", videoJobRoutes);
v1Router.use("/webhook", webhookRoutes);
v1Router.use("/generated-videos", generatedVideoRoutes);
v1Router.use("/", uploadRoutes); // Upload routes at /api/v1/upload

// Mount v1 routes
router.use("/v1", v1Router);

module.exports = router;
