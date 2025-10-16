const express = require("express");
const router = express.Router();
const logger = require("../utils/logger");
const { getPortfolioByStudent } = require("../controllers/portfolioController");

// Get portfolio entries for a student
router.get(
  "/:user_id",
  (req, res, next) => {
    logger.debug("GET /portfolio/:user_id route accessed", { userId: req.params.user_id });
    next();
  },
  getPortfolioByStudent
);

// Minimal POST /portfolio to create entry is not in controller; provider uses it.
// Implement inline handler here to avoid new controller file for now.
router.post(
  "/",
  (req, res, next) => {
    logger.debug("POST /portfolio route accessed", { bodyKeys: Object.keys(req.body) });
    next();
  },
  async (req, res) => {
    const supabase = require("../config/supabaseClient");
    logger.debug("Inline portfolio POST handler called", { bodyKeys: Object.keys(req.body) });

    function success(data) {
      logger.debug("Portfolio POST success response");
      return res.status(200).json({ success: true, data });
    }
    function error(msg, code = 400) {
      logger.warn("Portfolio POST error response", { message: msg, statusCode: code });
      return res.status(code).json({ success: false, error: msg });
    }
    try {
      const { user_id, submission_id } = req.body || {};
      if (!user_id || !submission_id) {
        logger.warn("Portfolio POST failed - Missing required fields", {
          hasUserId: !!user_id,
          hasSubmissionId: !!submission_id,
        });
        return error("user_id and submission_id are required");
      }

      logger.debug("Verifying submission belongs to user and is accepted", {
        userId: user_id,
        submissionId: submission_id,
      });
      // Ensure submission belongs to user and is accepted
      const { data: sub, error: subErr } = await supabase
        .from("submissions")
        .select("submission_id, user_id, status")
        .eq("submission_id", submission_id)
        .single();
      if (subErr) {
        logger.error("Failed to verify submission", {
          submissionId: submission_id,
          error: subErr.message,
        });
        throw subErr;
      }
      if (!sub || sub.user_id !== user_id) {
        logger.warn("Portfolio POST failed - Submission does not belong to user", {
          submissionUserId: sub?.user_id,
          requestUserId: user_id,
        });
        return error("Submission does not belong to user", 403);
      }
      if (sub.status !== "accepted") {
        logger.warn("Portfolio POST failed - Submission not accepted", {
          submissionId: submission_id,
          status: sub.status,
        });
        return error("Only accepted submissions can be added");
      }

      // Check if already exists
      logger.debug("Checking if portfolio entry already exists", { submissionId: submission_id });
      const { data: existing } = await supabase
        .from("portfolio_entries")
        .select("entry_id")
        .eq("submission_id", submission_id)
        .maybeSingle();
      if (existing) {
        logger.debug("Portfolio entry already exists, returning existing", {
          portfolioEntryId: existing.entry_id,
        });
        return success(existing);
      }

      logger.debug("Creating portfolio entry", { submissionId: submission_id });
      const { data, error: insErr } = await supabase
        .from("portfolio_entries")
        .insert([{ submission_id, verified: true }])
        .select()
        .single();
      if (insErr) {
        logger.error("Failed to create portfolio entry", {
          submissionId: submission_id,
          error: insErr.message,
        });
        throw insErr;
      }

      logger.info("Portfolio entry created successfully", {
        portfolioEntryId: data.entry_id,
        submissionId: submission_id,
      });
      return success(data);
    } catch (e) {
      logger.error("Portfolio POST error", { error: e.message, stack: e.stack });
      return error(e.message, 500);
    }
  }
);

module.exports = router;
