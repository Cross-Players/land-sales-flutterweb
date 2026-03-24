/**
 * In-memory store for video generation jobs.
 * Manages job state and SSE client connections.
 */

// Map<jobId, JobRecord>
const jobs = new Map();

// Map<jobId, Set<SseClient>>  — SSE response objects waiting on this job
const sseClients = new Map();

/**
 * @typedef {Object} JobRecord
 * @property {string}  id
 * @property {string}  templateId
 * @property {string}  status  - 'pending' | 'processing' | 'done' | 'error'
 * @property {string|null} videoUrl
 * @property {string|null} errorMessage
 * @property {Date}    createdAt
 * @property {Date}    updatedAt
 */

/**
 * Create a new job record.
 * @param {string} jobId
 * @param {string} templateId
 * @returns {JobRecord}
 */
function createJob(jobId, templateId) {
  const job = {
    id: jobId,
    templateId,
    status: "pending",
    videoUrl: null,
    errorMessage: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  jobs.set(jobId, job);
  sseClients.set(jobId, new Set());
  return job;
}

/**
 * Get job by id.
 * @param {string} jobId
 * @returns {JobRecord|undefined}
 */
function getJob(jobId) {
  return jobs.get(jobId);
}

/**
 * Update job to 'done' with videoUrl, and notify all SSE clients.
 * @param {string} jobId
 * @param {string} videoUrl
 */
function completeJob(jobId, videoUrl) {
  const job = jobs.get(jobId);
  if (!job) return;

  job.status = "done";
  job.videoUrl = videoUrl;
  job.updatedAt = new Date();

  _notifyClients(jobId, { status: "done", videoUrl, jobId });
}

/**
 * Update job to 'error', and notify all SSE clients.
 * @param {string} jobId
 * @param {string} message
 */
function failJob(jobId, message) {
  const job = jobs.get(jobId);
  if (!job) return;

  job.status = "error";
  job.errorMessage = message;
  job.updatedAt = new Date();

  _notifyClients(jobId, { status: "error", message, jobId });
}

/**
 * Update job status to 'processing'.
 * @param {string} jobId
 */
function markProcessing(jobId) {
  const job = jobs.get(jobId);
  if (!job) return;

  job.status = "processing";
  job.updatedAt = new Date();

  _notifyClients(jobId, { status: "processing", jobId });
}

/**
 * Register an SSE response object for a job.
 * Sends a heartbeat comment immediately to establish connection.
 * @param {string} jobId
 * @param {import('express').Response} res
 */
function registerSseClient(jobId, res) {
  if (!sseClients.has(jobId)) {
    sseClients.set(jobId, new Set());
  }
  sseClients.get(jobId).add(res);

  // Heartbeat every 20s to keep connection alive
  const heartbeat = setInterval(() => {
    if (!res.writableEnded) {
      res.write(": heartbeat\n\n");
    } else {
      clearInterval(heartbeat);
      sseClients.get(jobId)?.delete(res);
    }
  }, 20_000);

  // Clean up when client disconnects
  res.on("close", () => {
    clearInterval(heartbeat);
    sseClients.get(jobId)?.delete(res);
  });

  // If job already done/error, send immediately
  const job = jobs.get(jobId);
  if (job) {
    if (job.status === "done") {
      _sendEvent(res, { status: "done", videoUrl: job.videoUrl, jobId });
    } else if (job.status === "error") {
      _sendEvent(res, { status: "error", message: job.errorMessage, jobId });
    } else {
      // Send current status so client knows connection is alive
      _sendEvent(res, { status: job.status, jobId });
    }
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

function _notifyClients(jobId, payload) {
  const clients = sseClients.get(jobId);
  if (!clients || clients.size === 0) return;

  for (const res of clients) {
    if (!res.writableEnded) {
      _sendEvent(res, payload);
    }
  }

  // Auto-cleanup finished jobs after 10 minutes
  if (payload.status === "done" || payload.status === "error") {
    setTimeout(
      () => {
        jobs.delete(jobId);
        sseClients.delete(jobId);
      },
      10 * 60 * 1000,
    );
  }
}

function _sendEvent(res, data) {
  try {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  } catch (_) {
    // Connection already closed — ignore
  }
}

module.exports = {
  createJob,
  getJob,
  completeJob,
  failJob,
  markProcessing,
  registerSseClient,
};
