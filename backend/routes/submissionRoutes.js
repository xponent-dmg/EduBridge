const express = require("express");
const router = express.Router();
const multer = require("multer");
const {
  createSubmission,
  getSubmissionById,
  updateSubmissionStatus,
  getSubmissionsByTask,
  getFilesForSubmission,
} = require("../controllers/submissionController");

// Multer for multipart file uploads
const upload = multer({ storage: multer.memoryStorage() });

// Create new submission for a task with an attached file (field name: "file")
router.post("/", upload.single("file"), createSubmission);

// Get submission details
router.get("/:id", getSubmissionById);

// Update submission status + grade + feedback
router.patch("/:id/status", updateSubmissionStatus);

// Get files for a submission
router.get("/:id/files", getFilesForSubmission);

module.exports = router;
