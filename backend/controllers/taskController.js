const supabase = require("../config/supabaseClient");

// Helper functions
function success(res, data) {
  return res.status(200).json({ success: true, data });
}

function error(res, msg, code = 400) {
  return res.status(code).json({ success: false, error: msg });
}

// Create task (only company users can create tasks)
const createTask = async (req, res) => {
  try {
    const { posted_by, title, description, domains, effort_hours, expiry_date } = req.body;
    if (!posted_by || !title) return error(res, "posted_by and title are required");

    if (domains !== undefined && !Array.isArray(domains)) {
      return error(res, "domains must be an array if provided");
    }

    // Verify that posted_by is a valid company user
    const { data: company, error: companyError } = await supabase
      .from("users")
      .select("role")
      .eq("user_id", posted_by)
      .single();

    if (companyError) throw companyError;
    if (company.role !== "company") {
      return error(res, "Only company users can create tasks", 403);
    }

    // Create the task without domain column; domains stored separately
    const { data: task, error: taskError } = await supabase
      .from("tasks")
      .insert([{ posted_by, title, description, effort_hours, expiry_date }])
      .select()
      .single();

    if (taskError) throw taskError;

    // Insert domains if provided
    if (domains.length > 0) {
      const rowsToInsert = domains.map((d) => ({ task_id: task.task_id, domain: d }));
      const { error: domainsError } = await supabase.from("task_domains").insert(rowsToInsert);
      if (domainsError) throw domainsError;
    }

    // Fetch domains to include in response
    const { data: domainRows, error: fetchDomainsError } = await supabase
      .from("task_domains")
      .select("domain")
      .eq("task_id", task.task_id);
    if (fetchDomainsError) throw fetchDomainsError;
    const domainsList = (domainRows || []).map((row) => row.domain);

    success(res, { ...task, domains: domainsList });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get all tasks with domains
const getTasks = async (req, res) => {
  try {
    const { data: tasks, error: tasksError } = await supabase
      .from("tasks")
      .select(
        `
        task_id,
        title,
        description,
        effort_hours,
        expiry_date,
        created_at,
        posted_by,
        users!tasks_posted_by_fkey(name, email)
      `
      )
      .order("created_at", { ascending: false });

    if (tasksError) throw tasksError;

    const taskIds = (tasks || []).map((t) => t.task_id);
    if (taskIds.length === 0) return success(res, []);

    const { data: domainRows, error: domainsError } = await supabase
      .from("task_domains")
      .select("task_id, domain")
      .in("task_id", taskIds);
    if (domainsError) throw domainsError;

    const taskIdToDomains = new Map();
    for (const row of domainRows || []) {
      const list = taskIdToDomains.get(row.task_id) || [];
      list.push(row.domain);
      taskIdToDomains.set(row.task_id, list);
    }

    const result = tasks.map((t) => ({ ...t, domains: taskIdToDomains.get(t.task_id) || [] }));
    success(res, result);
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get task by ID with domains
const getTaskById = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: task, error: taskError } = await supabase
      .from("tasks")
      .select(
        `
        task_id,
        title,
        description,
        effort_hours,
        expiry_date,
        created_at,
        posted_by,
        users!tasks_posted_by_fkey(name, email)
      `
      )
      .eq("posted_by", id)
      .single();

    if (taskError) throw taskError;

    const { data: domainRows, error: domainsError } = await supabase
      .from("task_domains")
      .select("domain")
      .eq("task_id", id);
    if (domainsError) throw domainsError;
    const domains = (domainRows || []).map((r) => r.domain);

    success(res, { ...task, domains });
  } catch (e) {
    error(res, e.message, 500);
  }
};

module.exports = {
  createTask,
  getTasks,
  getTaskById,
};
