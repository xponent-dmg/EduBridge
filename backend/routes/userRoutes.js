const express = require("express");
const router = express.Router();
const logger = require("../utils/logger");
const {
  getUsers,
  createUser,
  getUserById,
  updateUserSkills,
  addUserSkills,
  removeUserSkills,
  getMe,
} = require("../controllers/userController");
const { authenticate } = require("../middleware/authMiddleware");

// Get all users
router.get(
  "/",
  (req, res, next) => {
    logger.debug("GET /users route accessed");
    next();
  },
  getUsers
);

// Get current authenticated user
router.get(
  "/me",
  (req, res, next) => {
    logger.debug("GET /users/me route accessed");
    next();
  },
  authenticate,
  getMe
);

// Create a new user
router.post(
  "/",
  (req, res, next) => {
    logger.debug("POST /users route accessed", { bodyKeys: Object.keys(req.body) });
    next();
  },
  createUser
);

// Get user by ID
router.get(
  "/:id",
  (req, res, next) => {
    logger.debug("GET /users/:id route accessed", { userId: req.params.id });
    next();
  },
  getUserById
);

// Update user skills (full replacement)
router.patch(
  "/:id/skills",
  (req, res, next) => {
    logger.debug("PATCH /users/:id/skills route accessed", { userId: req.params.id });
    next();
  },
  updateUserSkills
);

// Add skills to user
router.post(
  "/:id/skills",
  (req, res, next) => {
    logger.debug("POST /users/:id/skills route accessed", { userId: req.params.id });
    next();
  },
  addUserSkills
);

// Remove skills from user
router.delete(
  "/:id/skills",
  (req, res, next) => {
    logger.debug("DELETE /users/:id/skills route accessed", { userId: req.params.id });
    next();
  },
  removeUserSkills
);

module.exports = router;
