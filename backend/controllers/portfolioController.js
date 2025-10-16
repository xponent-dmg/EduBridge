const supabase = require("../config/supabaseClient");
const logger = require("../utils/logger");

// Helper functions
function success(res, data) {
  logger.debug("Sending success response", {
    dataType: typeof data,
    dataKeys: data ? Object.keys(data) : null,
  });
  return res.status(200).json({ success: true, data });
}

function error(res, msg, code = 400) {
  logger.warn("Sending error response", { message: msg, statusCode: code });
  return res.status(code).json({ success: false, error: msg });
}

// Get portfolio entries for a student
const getPortfolioByStudent = async (req, res) => {
  const { user_id } = req.params;
  logger.debug("getPortfolioByStudent called", { userId: user_id });

  try {
    logger.debug("Verifying user exists and is a student", { userId: user_id });
    // Verify user exists and role
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("role")
      .eq("user_id", user_id)
      .single();

    if (userError) {
      logger.error("Failed to verify user", { userId: user_id, error: userError.message });
      throw userError;
    }
    if (user.role !== "student") {
      logger.warn("getPortfolioByStudent failed - User not student", {
        userId: user_id,
        role: user.role,
      });
      return error(res, "Only students have portfolios");
    }

    logger.debug("Fetching approved submissions for user", { userId: user_id });
    // Get approved submissions for user
    const { data: submissions, error: subErr } = await supabase
      .from("submissions")
      .select("submission_id, task_id, grade, feedback, submit_time")
      .eq("user_id", user_id)
      .eq("status", "accepted")
      .order("submit_time", { ascending: false });
    if (subErr) {
      logger.error("Failed to fetch approved submissions", {
        userId: user_id,
        error: subErr.message,
      });
      throw subErr;
    }

    const submissionIds = (submissions || []).map((s) => s.submission_id);
    logger.debug("Approved submissions fetched", {
      userId: user_id,
      submissionsCount: submissionIds.length,
    });

    if (submissionIds.length === 0) {
      logger.debug("No approved submissions found, returning empty array", { userId: user_id });
      return success(res, []);
    }

    logger.debug("Fetching portfolio entries", { submissionIdsCount: submissionIds.length });
    // Get portfolio entries linked to those submissions
    const { data: entries, error: peErr } = await supabase
      .from("portfolio_entries")
      .select("entry_id, submission_id, added_at, verified")
      .in("submission_id", submissionIds)
      .order("added_at", { ascending: false });
    if (peErr) {
      logger.error("Failed to fetch portfolio entries", { error: peErr.message });
      throw peErr;
    }

    // Fetch tasks for those submissions
    const taskIds = Array.from(new Set((submissions || []).map((s) => s.task_id)));
    logger.debug("Fetching tasks for submissions", { taskIdsCount: taskIds.length });
    const { data: tasks, error: tErr } = await supabase
      .from("tasks")
      .select("task_id, title, description, effort_hours, expiry_date, created_at, posted_by")
      .in("task_id", taskIds);
    if (tErr) {
      logger.error("Failed to fetch tasks", { error: tErr.message });
      throw tErr;
    }
    const taskIdToTask = new Map((tasks || []).map((t) => [t.task_id, t]));

    // Domains for tasks
    logger.debug("Fetching task domains");
    const { data: domainRows, error: dErr } = await supabase
      .from("task_domains")
      .select("task_id, domain")
      .in("task_id", taskIds);
    if (dErr) {
      logger.error("Failed to fetch task domains", { error: dErr.message });
      throw dErr;
    }
    const taskIdToDomains = new Map();
    for (const row of domainRows || []) {
      const list = taskIdToDomains.get(row.task_id) || [];
      list.push(row.domain);
      taskIdToDomains.set(row.task_id, list);
    }

    logger.debug("Processing portfolio data", {
      submissionsCount: submissions.length,
      entriesCount: entries.length,
      tasksCount: tasks.length,
      domainsCount: domainRows.length,
    });

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

    logger.debug("getPortfolioByStudent completed successfully", {
      userId: user_id,
      portfolioEntriesCount: result.length,
    });

    success(res, result);
  } catch (e) {
    logger.error("getPortfolioByStudent error", {
      userId: user_id,
      error: e.message,
      stack: e.stack,
    });
    error(res, e.message, 500);
  }
};

module.exports = {
  getPortfolioByStudent,
};
