const express = require("express");
const router = express.Router();
const {
  getPortfolioByStudent,
} = require("../controllers/portfolioController");

// Get portfolio entries for a student
router.get("/:user_id", getPortfolioByStudent);

module.exports = router;
