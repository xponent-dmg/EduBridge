const supabase = require("../config/supabaseClient");

// Helper functions
function success(res, data) {
  return res.status(200).json({ success: true, data });
}

function error(res, msg, code = 400) {
  return res.status(code).json({ success: false, error: msg });
}

// Get portfolio entries for a student
const getPortfolioByStudent = async (req, res) => {
  try {
    const { user_id } = req.params;

    // Verify user is a student
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("role")
      .eq("user_id", user_id)
      .single();

    if (userError) throw userError;
    if (user.role !== "student") {
      return error(res, "Only students have portfolios");
    }

    const { data: entries, error: dbError } = await supabase
      .from("portfolio_entries")
      .select(
        `
        entry_id,
        added_at,
        verified,
        submissions!inner(
          submission_id,
          grade,
          feedback,
          tasks(
            task_id,
            title,
            description,
            domain,
            effort_hours
          )
        )
      `
      )
      .eq("submissions.student_id", user_id)
      .eq("submissions.status", "approved")
      .order("added_at", { ascending: false });

    if (dbError) throw dbError;
    success(res, entries || []);
  } catch (e) {
    error(res, e.message, 500);
  }
};

module.exports = {
  getPortfolioByStudent,
};
