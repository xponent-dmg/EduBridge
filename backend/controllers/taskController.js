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

// Create task (only company users can create tasks)
const createTask = async (req, res) => {
  logger.debug("createTask called", {
    bodyKeys: Object.keys(req.body),
    hasPostedBy: !!req.body.posted_by,
    hasTitle: !!req.body.title,
    domainsCount: req.body.domains?.length,
  });

  try {
    const { posted_by, title, description, domains, effort_hours, expiry_date } = req.body;
    if (!posted_by || !title) {
      logger.warn("createTask failed - Missing required fields", {
        hasPostedBy: !!posted_by,
        hasTitle: !!title,
      });
      return error(res, "posted_by and title are required");
    }

    if (domains !== undefined && !Array.isArray(domains)) {
      logger.warn("createTask failed - domains not array", { domainsType: typeof domains });
      return error(res, "domains must be an array if provided");
    }

    logger.debug("Verifying posted_by is company user", { postedBy: posted_by });
    // Verify that posted_by is a valid company user
    const { data: company, error: companyError } = await supabase
      .from("users")
      .select("role")
      .eq("user_id", posted_by)
      .single();

    if (companyError) {
      logger.error("Failed to verify company user", {
        postedBy: posted_by,
        error: companyError.message,
      });
      throw companyError;
    }
    if (company.role !== "company") {
      logger.warn("createTask failed - User not company", {
        postedBy: posted_by,
        role: company.role,
      });
      return error(res, "Only company users can create tasks", 403);
    }

    logger.debug("Creating task in database", { postedBy: posted_by, title });
    // Create the task without domain column; domains stored separately
    const { data: task, error: taskError } = await supabase
      .from("tasks")
      .insert([{ posted_by, title, description, effort_hours, expiry_date }])
      .select()
      .single();

    if (taskError) {
      logger.error("Failed to create task", {
        postedBy: posted_by,
        title,
        error: taskError.message,
      });
      throw taskError;
    }

    logger.debug("Task created successfully", { taskId: task.task_id });

    // Insert domains if provided
    if (domains && domains.length > 0) {
      logger.debug("Inserting task domains", {
        taskId: task.task_id,
        domainsCount: domains.length,
      });
      const rowsToInsert = domains.map((d) => ({ task_id: task.task_id, domain: d }));
      const { error: domainsError } = await supabase.from("task_domains").insert(rowsToInsert);
      if (domainsError) {
        logger.error("Failed to insert task domains", {
          taskId: task.task_id,
          error: domainsError.message,
        });
        throw domainsError;
      }
    }

    // Fetch domains to include in response
    logger.debug("Fetching task domains for response", { taskId: task.task_id });
    const { data: domainRows, error: fetchDomainsError } = await supabase
      .from("task_domains")
      .select("domain")
      .eq("task_id", task.task_id);
    if (fetchDomainsError) {
      logger.error("Failed to fetch task domains", {
        taskId: task.task_id,
        error: fetchDomainsError.message,
      });
      throw fetchDomainsError;
    }
    const domainsList = (domainRows || []).map((row) => row.domain);

    logger.info("Task created successfully", {
      taskId: task.task_id,
      title,
      domainsCount: domainsList.length,
    });
    success(res, { ...task, domains: domainsList });
  } catch (e) {
    logger.error("createTask error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Get all tasks with domains
const getTasks = async (req, res) => {
  logger.debug("getTasks called");

  try {
    logger.debug("Fetching all tasks from database");
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

    if (tasksError) {
      logger.error("Failed to fetch tasks", { error: tasksError.message });
      throw tasksError;
    }

    const taskIds = (tasks || []).map((t) => t.task_id);
    logger.debug("Tasks fetched", { tasksCount: taskIds.length });

    if (taskIds.length === 0) {
      logger.debug("No tasks found, returning empty array");
      return success(res, []);
    }

    logger.debug("Fetching task domains", { taskIdsCount: taskIds.length });
    const { data: domainRows, error: domainsError } = await supabase
      .from("task_domains")
      .select("task_id, domain")
      .in("task_id", taskIds);
    if (domainsError) {
      logger.error("Failed to fetch task domains", { error: domainsError.message });
      throw domainsError;
    }

    const taskIdToDomains = new Map();
    for (const row of domainRows || []) {
      const list = taskIdToDomains.get(row.task_id) || [];
      list.push(row.domain);
      taskIdToDomains.set(row.task_id, list);
    }

    logger.debug("Processing domains mapping", { domainsRowsCount: (domainRows || []).length });

    const result = tasks.map((t) => ({ ...t, domains: taskIdToDomains.get(t.task_id) || [] }));
    logger.debug("getTasks completed successfully", { resultCount: result.length });

    success(res, result);
  } catch (e) {
    logger.error("getTasks error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Get task by ID with domains
const getTaskById = async (req, res) => {
  const { id } = req.params;
  logger.debug("getTaskById called", { taskId: id });

  try {
    logger.debug("Fetching task by ID", { taskId: id });
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
      .eq("task_id", id)
      .single();

    if (taskError) {
      logger.error("Failed to fetch task by ID", { taskId: id, error: taskError.message });
      throw taskError;
    }

    logger.debug("Task found, fetching domains", { taskId: id });
    const { data: domainRows, error: domainsError } = await supabase
      .from("task_domains")
      .select("domain")
      .eq("task_id", id);
    if (domainsError) {
      logger.error("Failed to fetch task domains", { taskId: id, error: domainsError.message });
      throw domainsError;
    }
    const domains = (domainRows || []).map((r) => r.domain);

    logger.debug("getTaskById completed successfully", {
      taskId: id,
      domainsCount: domains.length,
    });
    success(res, { ...task, domains });
  } catch (e) {
    logger.error("getTaskById error", { taskId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

module.exports = {
  createTask,
  getTasks,
  getTaskById,
  // List tasks by company id (posted_by)
  getTasksByCompany: async (req, res) => {
    const { companyId } = req.params;
    logger.debug("getTasksByCompany called", { companyId });

    if (!companyId) {
      return error(res, "companyId is required", 400);
    }

    try {
      logger.debug("Fetching tasks for company", { companyId });
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
        .eq("posted_by", companyId)
        .order("created_at", { ascending: false });

      if (tasksError) {
        logger.error("Failed to fetch tasks by company", { companyId, error: tasksError.message });
        throw tasksError;
      }

      const taskIds = (tasks || []).map((t) => t.task_id);
      if (taskIds.length === 0) {
        return success(res, []);
      }

      const { data: domainRows, error: domainsError } = await supabase
        .from("task_domains")
        .select("task_id, domain")
        .in("task_id", taskIds);
      if (domainsError) {
        logger.error("Failed to fetch domains for company tasks", { error: domainsError.message });
        throw domainsError;
      }

      const taskIdToDomains = new Map();
      for (const row of domainRows || []) {
        const list = taskIdToDomains.get(row.task_id) || [];
        list.push(row.domain);
        taskIdToDomains.set(row.task_id, list);
      }

      const result = (tasks || []).map((t) => ({
        ...t,
        domains: taskIdToDomains.get(t.task_id) || [],
      }));
      success(res, result);
    } catch (e) {
      logger.error("getTasksByCompany error", { companyId, error: e.message, stack: e.stack });
      error(res, e.message, 500);
    }
  },
};
