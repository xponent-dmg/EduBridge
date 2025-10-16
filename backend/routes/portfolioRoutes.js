const express = require("express");
const router = express.Router();
const { getPortfolioByStudent } = require("../controllers/portfolioController");

// Get portfolio entries for a student
router.get("/:user_id", getPortfolioByStudent);

// Minimal POST /portfolio to create entry is not in controller; provider uses it.
// Implement inline handler here to avoid new controller file for now.
router.post("/", async (req, res) => {
  const supabase = require("../config/supabaseClient");
  function success(data) {
    return res.status(200).json({ success: true, data });
  }
  function error(msg, code = 400) {
    return res.status(code).json({ success: false, error: msg });
  }
  try {
    const { user_id, submission_id } = req.body || {};
    if (!user_id || !submission_id) return error("user_id and submission_id are required");

    // Ensure submission belongs to user and is accepted
    const { data: sub, error: subErr } = await supabase
      .from("submissions")
      .select("submission_id, user_id, status")
      .eq("submission_id", submission_id)
      .single();
    if (subErr) throw subErr;
    if (!sub || sub.user_id !== user_id) return error("Submission does not belong to user", 403);
    if (sub.status !== "accepted") return error("Only accepted submissions can be added");

    // Check if already exists
    const { data: existing } = await supabase
      .from("portfolio_entries")
      .select("entry_id")
      .eq("submission_id", submission_id)
      .maybeSingle();
    if (existing) return success(existing);

    const { data, error: insErr } = await supabase
      .from("portfolio_entries")
      .insert([{ submission_id, verified: true }])
      .select()
      .single();
    if (insErr) throw insErr;
    return success(data);
  } catch (e) {
    return error(e.message, 500);
  }
});

module.exports = router;
