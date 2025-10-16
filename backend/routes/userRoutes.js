const express = require("express");
const router = express.Router();
const {
  getUsers,
  createUser,
  getUserById,
  updateUserSkills,
  addUserSkills,
  removeUserSkills,
} = require("../controllers/userController");

// Get all users
router.get("/", getUsers);

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
