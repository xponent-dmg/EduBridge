const express = require("express");
const router = express.Router();
const {
  redeemPoints,
  getUserTransactions,
  awardPoints,
} = require("../controllers/edupointsController");

// Redeem points for user
router.post("/redeem", redeemPoints);

// Award points for user
router.post("/award", awardPoints);

// Get all transactions for a user
router.get("/:user_id", getUserTransactions);

module.exports = router;
