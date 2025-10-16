const express = require("express");
const router = express.Router();
const logger = require("../utils/logger");
const { createTask, getTasks, getTaskById } = require("../controllers/taskController");
const { getSubmissionsByTask } = require("../controllers/submissionController");

// Create task (only company users)
router.post(
  "/",
  (req, res, next) => {
    logger.debug("POST /tasks route accessed", { bodyKeys: Object.keys(req.body) });
    next();
  },
  createTask
);

// Get all tasks
router.get(
  "/",
  (req, res, next) => {
    logger.debug("GET /tasks route accessed");
    next();
  },
  getTasks
);

// Get task by ID
router.get(
  "/:id",
  (req, res, next) => {
    logger.debug("GET /tasks/:id route accessed", { taskId: req.params.id });
    next();
  },
  getTaskById
);

// Get submissions for a task
router.get(
  "/:id/submissions",
  (req, res, next) => {
    logger.debug("GET /tasks/:id/submissions route accessed", { taskId: req.params.id });
    next();
  },
  getSubmissionsByTask
);

module.exports = router;
