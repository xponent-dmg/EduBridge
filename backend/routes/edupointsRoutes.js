const express = require("express");
const router = express.Router();
const logger = require("../utils/logger");
const {
  redeemPoints,
  getUserTransactions,
  awardPoints,
} = require("../controllers/edupointsController");

// Redeem points for user
router.post(
  "/redeem",
  (req, res, next) => {
    logger.debug("POST /edupoints/redeem route accessed", { bodyKeys: Object.keys(req.body) });
    next();
  },
  redeemPoints
);

// Award points for user
router.post(
  "/award",
  (req, res, next) => {
    logger.debug("POST /edupoints/award route accessed", { bodyKeys: Object.keys(req.body) });
    next();
  },
  awardPoints
);

// Get all transactions for a user
router.get(
  "/:user_id",
  (req, res, next) => {
    logger.debug("GET /edupoints/:user_id route accessed", { userId: req.params.user_id });
    next();
  },
  getUserTransactions
);

module.exports = router;
