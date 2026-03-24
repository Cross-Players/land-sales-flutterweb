/**
 * File Upload Routes
 * Handle file uploads to local storage
 */

const express = require("express");
const multer = require("multer");
const localStorageService = require("../services/googleDriveService"); // Renamed but same service

const router = express.Router();

// Configure multer for memory storage (store in RAM, not disk)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB max file size
  },
  fileFilter: (req, file, cb) => {
    // Accept only images and videos
    const allowedTypes = /jpeg|jpg|png|gif|webp|mp4|mov|avi|webm/;
    const mimetype = allowedTypes.test(file.mimetype);
    const extname = allowedTypes.test(
      file.originalname.toLowerCase().split(".").pop(),
    );

    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error("Only image and video files are allowed!"));
  },
});

/**
 * POST /api/v1/upload
 * Upload file to local storage
 *
 * Body: multipart/form-data
 * - file: File to upload
 *
 * Response:
 * {
 *   success: true,
 *   data: {
 *     id: "timestamp_filename.ext",
 *     url: "http://localhost:3001/uploads/timestamp_filename.ext",
 *     fileName: "timestamp_filename.ext"
 *   }
 * }
 */
router.post("/upload", upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: "No file uploaded",
      });
    }

    const file = req.file;
    const mimeType = localStorageService.getMimeType(file.originalname);

    // Upload to local storage
    const result = await localStorageService.uploadFile(
      file.buffer,
      file.originalname,
      mimeType,
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /api/v1/upload/:fileId
 * Delete file from local storage
 */
router.delete("/upload/:fileId", async (req, res) => {
  try {
    const { fileId } = req.params;

    await localStorageService.deleteFile(fileId);

    res.json({
      success: true,
      message: "File deleted successfully",
    });
  } catch (error) {
    console.error("Delete error:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
