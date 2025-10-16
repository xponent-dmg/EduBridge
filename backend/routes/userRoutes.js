const express = require("express");
const router = express.Router();
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
router.get("/", getUsers);

// Get current authenticated user
router.get("/me", authenticate, getMe);

// Create a new user
router.post("/", createUser);

// Get user by ID
router.get("/:id", getUserById);

// Update user skills (full replacement)
router.patch("/:id/skills", updateUserSkills);

// Add skills to user
router.post("/:id/skills", addUserSkills);

// Remove skills from user
router.delete("/:id/skills", removeUserSkills);

module.exports = router;
