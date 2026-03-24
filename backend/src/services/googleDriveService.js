/**
 * Local File Storage Service
 * Upload files to local server and return public URLs via Cloudflare tunnel
 */

const fs = require("fs").promises;
const path = require("path");

class LocalStorageService {
  constructor() {
    // Upload directory
    this.uploadDir = path.join(__dirname, "../../uploads");

    // Ensure upload directory exists
    this.ensureUploadDir();
  }

  async ensureUploadDir() {
    try {
      await fs.mkdir(this.uploadDir, { recursive: true });
      console.log("✅ Upload directory ready:", this.uploadDir);
    } catch (error) {
      console.error("❌ Error creating upload directory:", error);
    }
  }

  /**
   * Upload file to local storage
   * @param {Buffer} fileBuffer - File buffer
   * @param {string} fileName - Original filename
   * @param {string} mimeType - MIME type of file
   * @returns {Promise<{id: string, url: string, fileName: string}>} File info and public URL
   */
  async uploadFile(fileBuffer, fileName, mimeType) {
    try {
      // Generate unique filename with timestamp
      const timestamp = Date.now();
      const ext = path.extname(fileName);
      const baseName = path.basename(fileName, ext);
      const uniqueFileName = `${timestamp}_${baseName}${ext}`;

      // File path
      const filePath = path.join(this.uploadDir, uniqueFileName);

      // Write file to disk
      await fs.writeFile(filePath, fileBuffer);

      // Generate public URL (using base URL from env or default)
      const baseUrl = process.env.PUBLIC_URL || "http://localhost:3001";
      const publicUrl = `${baseUrl}/uploads/${uniqueFileName}`;

      console.log(`✅ File saved locally: ${uniqueFileName}`);
      console.log(`📎 Public URL: ${publicUrl}`);

      return {
        id: uniqueFileName, // Use filename as ID
        url: publicUrl,
        fileName: uniqueFileName,
      };
    } catch (error) {
      console.error("❌ Error uploading to local storage:", error);
      throw new Error(`Local storage upload failed: ${error.message}`);
    }
  }

  /**
   * Delete file from local storage
   * @param {string} fileId - Filename to delete
   */
  async deleteFile(fileId) {
    try {
      const filePath = path.join(this.uploadDir, fileId);
      await fs.unlink(filePath);
      console.log(`✅ File deleted from local storage: ${fileId}`);
    } catch (error) {
      console.error("❌ Error deleting from local storage:", error);
      throw error;
    }
  }

  /**
   * Get MIME type from file extension
   * @param {string} filename
   * @returns {string} MIME type
   */
  getMimeType(filename) {
    const ext = filename.split(".").pop().toLowerCase();
    const mimeTypes = {
      // Images
      jpg: "image/jpeg",
      jpeg: "image/jpeg",
      png: "image/png",
      gif: "image/gif",
      webp: "image/webp",

      // Videos
      mp4: "video/mp4",
      mov: "video/quicktime",
      avi: "video/x-msvideo",
      webm: "video/webm",
    };

    return mimeTypes[ext] || "application/octet-stream";
  }
}

module.exports = new LocalStorageService();
