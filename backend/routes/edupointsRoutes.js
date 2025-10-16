const express = require("express");
const router = express.Router();
const { redeemPoints, getUserTransactions } = require("../controllers/edupointsController");

// Redeem points for user
router.post("/redeem", redeemPoints);

// Get all transactions for a user
router.get("/:user_id", getUserTransactions);

module.exports = router;
