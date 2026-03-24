const mongoose = require("mongoose");

const generatedVideoSchema = new mongoose.Schema(
  {
    jobId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    templateId: {
      type: String,
      default: null,
    },
    videoUrl: {
      type: String,
      required: true,
    },
    // Metadata gửi kèm từ n8n (title, description, v.v.)
    meta: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    // Không dùng timestamps tự động để giữ createdAt từ job gốc
    timestamps: false,
    versionKey: false,
  },
);

const GeneratedVideo =
  mongoose.models.GeneratedVideo ||
  mongoose.model("GeneratedVideo", generatedVideoSchema);

module.exports = GeneratedVideo;
