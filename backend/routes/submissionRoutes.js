const express = require("express");
const router = express.Router();
const multer = require("multer");
const logger = require("../utils/logger");
const { authenticate } = require("../middleware/authMiddleware");
const {
  createSubmission,
  getSubmissionById,
  updateSubmissionStatus,
  getSubmissionsByTask,
  getSubmissionsByUser,
  updateSubmissionGrade,
  getFilesForSubmission,
} = require("../controllers/submissionController");

// Multer for multipart file uploads
const upload = multer({ storage: multer.memoryStorage() });

// Create new submission for a task with an attached file (field name: "file")
// Authenticate BEFORE accepting file upload to avoid storing unauthorized uploads
router.post(
  "/",
  (req, res, next) => {
    logger.debug("POST /submissions route accessed (pre-auth)");
    next();
  },
  authenticate,
  upload.single("file"),
  (req, res, next) => {
    logger.debug("POST /submissions route accessed (post-upload)", {
      hasFile: !!req.file,
      fileName: req.file?.originalname,
      bodyKeys: Object.keys(req.body || {}),
      authUserId: req.user?.id,
    });
    next();
  },
  createSubmission
);

// Get submission details
router.get(
  "/:id",
  (req, res, next) => {
    logger.debug("GET /submissions/:id route accessed", { submissionId: req.params.id });
    next();
  },
  getSubmissionById
);

// Update submission status + grade + feedback
router.patch(
  "/:id/status",
  (req, res, next) => {
    logger.debug("PATCH /submissions/:id/status route accessed", { submissionId: req.params.id });
    next();
  },
  updateSubmissionStatus
);

// Get files for a submission
router.get(
  "/:id/files",
  (req, res, next) => {
    logger.debug("GET /submissions/:id/files route accessed", { submissionId: req.params.id });
    next();
  },
  getFilesForSubmission
);

// Additional endpoints used by frontend providers
router.get(
  "/task/:id",
  (req, res, next) => {
    logger.debug("GET /submissions/task/:id route accessed", { taskId: req.params.id });
    next();
  },
  getSubmissionsByTask
);

router.get(
  "/user/:id",
  (req, res, next) => {
    logger.debug("GET /submissions/user/:id route accessed", { userId: req.params.id });
    next();
  },
  getSubmissionsByUser
);

router.patch(
  "/:id/grade",
  (req, res, next) => {
    logger.debug("PATCH /submissions/:id/grade route accessed", { submissionId: req.params.id });
    next();
  },
  updateSubmissionGrade
);

module.exports = router;
