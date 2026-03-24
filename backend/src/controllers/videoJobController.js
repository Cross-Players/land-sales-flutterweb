const { v4: uuidv4 } = require("uuid");
const axios = require("axios");
const mongoose = require("mongoose");
const jobStore = require("../services/videoJobStore");
const GeneratedVideo = require("../data/generatedVideoModel");

// URL n8n webhook — đổi thành production khi cần
const N8N_WEBHOOK_URL =
  process.env.N8N_WEBHOOK_URL ||
  "https://primary-production-29ad2.up.railway.app/webhook/facebook-auto-post";

/**
 * POST /api/v1/video-jobs
 * Tạo job mới, trả về jobId cho Flutter.
 * Flutter sẽ dùng jobId này khi trigger n8n.
 */
async function createVideoJob(req, res) {
  try {
    const { templateId } = req.body;

    if (!templateId) {
      return res.status(400).json({ error: "templateId is required" });
    }

    const jobId = uuidv4();
    const job = jobStore.createJob(jobId, templateId);

    console.log(`✅ Job created: ${jobId} (template: ${templateId})`);

    return res.status(201).json({
      jobId: job.id,
      status: job.status,
      createdAt: job.createdAt,
    });
  } catch (err) {
    console.error("❌ createVideoJob error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}

/**
 * POST /api/v1/video-jobs/:jobId/trigger
 * Flutter gọi endpoint này thay vì gọi n8n trực tiếp.
 * Backend proxy request tới n8n → tránh CORS trên Flutter Web.
 * Body: { templateId, video: [...], ...any extra fields }
 */
async function triggerN8nJob(req, res) {
  try {
    const { jobId } = req.params;
    const job = jobStore.getJob(jobId);

    if (!job) {
      return res.status(404).json({ error: "Job not found" });
    }

    // Trả về 202 ngay cho Flutter — không chờ n8n
    res.status(202).json({ ok: true, jobId, status: "triggering" });

    // Gọi n8n ở background (không await trước res)
    try {
      jobStore.markProcessing(jobId);
      await axios.post(
        N8N_WEBHOOK_URL,
        { ...req.body, jobId },
        {
          headers: { "Content-Type": "application/json" },
          timeout: 30_000,
        },
      );
      console.log(`🚀 n8n triggered for job: ${jobId}`);
    } catch (n8nErr) {
      console.error(
        `❌ Failed to trigger n8n for job ${jobId}:`,
        n8nErr.message,
      );
      jobStore.failJob(jobId, `Failed to trigger n8n: ${n8nErr.message}`);
    }
  } catch (err) {
    console.error("❌ triggerN8nJob error:", err);
    // res đã được gửi rồi nên không gửi lại
  }
}

/**
 * GET /api/v1/video-jobs/:jobId
 * Lấy trạng thái job (fallback khi SSE bị ngắt).
 */
async function getVideoJob(req, res) {
  try {
    const { jobId } = req.params;
    const job = jobStore.getJob(jobId);

    if (!job) {
      return res.status(404).json({ error: "Job not found" });
    }

    return res.json({
      jobId: job.id,
      status: job.status,
      videoUrl: job.videoUrl,
      errorMessage: job.errorMessage,
      createdAt: job.createdAt,
      updatedAt: job.updatedAt,
    });
  } catch (err) {
    console.error("❌ getVideoJob error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}

/**
 * GET /api/v1/video-jobs/:jobId/stream
 * SSE endpoint — Flutter subscribe vào đây sau khi có jobId.
 * Giữ kết nối mở cho đến khi nhận được 'done' hoặc 'error'.
 */
async function streamVideoJob(req, res) {
  const { jobId } = req.params;

  const job = jobStore.getJob(jobId);
  if (!job) {
    return res.status(404).json({ error: "Job not found" });
  }

  // Set SSE headers
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no"); // Disable nginx buffering
  res.flushHeaders();

  console.log(`📡 SSE client connected for job: ${jobId}`);

  // Register client — store handles sending current status + future events
  jobStore.registerSseClient(jobId, res);
}

/**
 * POST /api/v1/webhook/video-done
 * n8n gọi vào đây sau khi generate video xong.
 * Body: { jobId, videoUrl }
 */
async function videoWebhookDone(req, res) {
  try {
    const { jobId, videoUrl, error } = req.body;

    if (!jobId) {
      return res.status(400).json({ error: "jobId is required" });
    }

    const job = jobStore.getJob(jobId);
    if (!job) {
      console.warn(`⚠️  webhook/video-done: job not found: ${jobId}`);
      // Still return 200 to not confuse n8n
      return res.json({ ok: true, warning: "Job not found, may have expired" });
    }

    if (error) {
      // n8n reported an error
      jobStore.failJob(jobId, error);
      console.log(`❌ Job failed: ${jobId} — ${error}`);
    } else if (!videoUrl) {
      jobStore.failJob(jobId, "No videoUrl provided by n8n");
      console.log(`❌ Job failed (no videoUrl): ${jobId}`);
    } else {
      jobStore.completeJob(jobId, videoUrl);
      console.log(`🎬 Job done: ${jobId} → ${videoUrl}`);

      // ── Lưu vào MongoDB (nếu kết nối) ─────────────────────────────────
      if (mongoose.connection.readyState === 1) {
        try {
          // Lấy templateId từ job store
          const job = jobStore.getJob(jobId);
          const { jobId: _jid, videoUrl: _vu, error: _e, ...meta } = req.body;

          await GeneratedVideo.findOneAndUpdate(
            { jobId },
            {
              jobId,
              templateId: job?.templateId ?? null,
              videoUrl,
              meta,
              createdAt: new Date(),
            },
            { upsert: true, new: true },
          );
          console.log(`💾 Saved to MongoDB: ${jobId}`);
        } catch (dbErr) {
          console.error("❌ MongoDB save error:", dbErr.message);
          // Không fail webhook vì lỗi DB
        }
      }
    }

    return res.json({ ok: true });
  } catch (err) {
    console.error("❌ videoWebhookDone error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}

module.exports = {
  createVideoJob,
  triggerN8nJob,
  getVideoJob,
  streamVideoJob,
  videoWebhookDone,
};
