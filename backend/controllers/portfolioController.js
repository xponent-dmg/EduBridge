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

    // Verify user exists and role
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("role")
      .eq("user_id", user_id)
      .single();

    if (userError) throw userError;
    if (user.role !== "student") {
      return error(res, "Only students have portfolios");
    }

    // Get approved submissions for user
    const { data: submissions, error: subErr } = await supabase
      .from("submissions")
      .select("submission_id, task_id, grade, feedback, submit_time")
      .eq("user_id", user_id)
      .eq("status", "accepted")
      .order("submit_time", { ascending: false });
    if (subErr) throw subErr;

    const submissionIds = (submissions || []).map((s) => s.submission_id);
    if (submissionIds.length === 0) return success(res, []);

    // Get portfolio entries linked to those submissions
    const { data: entries, error: peErr } = await supabase
      .from("portfolio_entries")
      .select("entry_id, submission_id, added_at, verified")
      .in("submission_id", submissionIds)
      .order("added_at", { ascending: false });
    if (peErr) throw peErr;

    // Fetch tasks for those submissions
    const taskIds = Array.from(new Set((submissions || []).map((s) => s.task_id)));
    const { data: tasks, error: tErr } = await supabase
      .from("tasks")
      .select("task_id, title, description, effort_hours, expiry_date, created_at, posted_by")
      .in("task_id", taskIds);
    if (tErr) throw tErr;
    const taskIdToTask = new Map((tasks || []).map((t) => [t.task_id, t]));

    // Domains for tasks
    const { data: domainRows, error: dErr } = await supabase
      .from("task_domains")
      .select("task_id, domain")
      .in("task_id", taskIds);
    if (dErr) throw dErr;
    const taskIdToDomains = new Map();
    for (const row of domainRows || []) {
      const list = taskIdToDomains.get(row.task_id) || [];
      list.push(row.domain);
      taskIdToDomains.set(row.task_id, list);
    }

    // Shape response to match frontend model
    const subIdToSubmission = new Map((submissions || []).map((s) => [s.submission_id, s]));
    const result = (entries || []).map((e) => {
      const s = subIdToSubmission.get(e.submission_id);
      const t = s ? taskIdToTask.get(s.task_id) : null;
      return {
        portfolio_id: e.entry_id,
        user_id,
        added_at: e.added_at,
        submissions: {
          submission_id: s?.submission_id,
          task_id: s?.task_id,
          user_id,
          grade: s?.grade,
          feedback: s?.feedback,
          submitted_at: s?.submit_time,
          tasks: t
            ? {
                task_id: t.task_id,
                title: t.title,
                description: t.description,
                domains: taskIdToDomains.get(t.task_id) || [],
                effort_hours: t.effort_hours,
                posted_by: t.posted_by,
                created_at: t.created_at,
                expiry_date: t.expiry_date,
              }
            : null,
        },
      };
    });

    success(res, result);
  } catch (e) {
    error(res, e.message, 500);
  }
};

module.exports = {
  getPortfolioByStudent,
};
