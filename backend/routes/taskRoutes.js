const express = require("express");
const router = express.Router();
const { createTask, getTasks, getTaskById } = require("../controllers/taskController");
const { getSubmissionsByTask } = require("../controllers/submissionController");

// Create task (only company users)
router.post("/", createTask);

// Get all tasks
router.get("/", getTasks);

// Get task by ID
router.get("/:id", getTaskById);

// Get submissions for a task
router.get("/:id/submissions", getSubmissionsByTask);

module.exports = router;
