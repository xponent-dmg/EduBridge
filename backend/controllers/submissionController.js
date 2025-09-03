const supabase = require("../config/supabaseClient");

// Helper functions
function success(res, data) {
  return res.status(200).json({ success: true, data });
}

function error(res, msg, code = 400) {
  return res.status(code).json({ success: false, error: msg });
}

// Internal: store an uploaded file for a submission and persist its DB record
async function storeSubmissionFile(submissionId, file) {
  if (!file) throw new Error("file is required");
  const bucket = process.env.SUPABASE_SUBMISSIONS_BUCKET;
  if (!bucket) throw new Error("SUPABASE_SUBMISSIONS_BUCKET is not configured");

  const fileBuffer = file.buffer;
  const fileType = file.mimetype || "application/octet-stream";
  const originalName = file.originalname || "upload.bin";
  const objectPath = `submissions/${submissionId}/${Date.now()}_${originalName}`;

  const { data: uploadData, error: uploadError } = await supabase.storage
    .from(bucket)
    .upload(objectPath, fileBuffer, { contentType: fileType, upsert: false });
  if (uploadError) throw uploadError;

  const { data: publicUrlData } = supabase.storage.from(bucket).getPublicUrl(objectPath);
  const publicUrl = publicUrlData?.publicUrl || null;

  const { data: fileRecord, error: fileInsertError } = await supabase
    .from("files")
    .insert([
      {
        submission_id: submissionId,
        object_path: objectPath,
        file_path: publicUrl,
        file_type: fileType,
      },
    ])
    .select()
    .single();
  if (fileInsertError) throw fileInsertError;

  return fileRecord;
}

// Create submission
const createSubmission = async (req, res) => {
  try {
    const { task_id, user_id } = req.body;
    if (!task_id || !user_id) return error(res, "task_id and user_id are required");
    if (!req.file) return error(res, "file is required");

    // Verify student exists and is a student
    const { data: student, error: studentError } = await supabase
      .from("users")
      .select("role")
      .eq("user_id", user_id)
      .single();

    if (studentError) throw studentError;
    if (student.role !== "student") {
      return error(res, "Only students can create submissions", 403);
    }

    // Verify task exists
    const { data: task, error: taskError } = await supabase
      .from("tasks")
      .select("task_id")
      .eq("task_id", task_id)
      .single();

    if (taskError) throw taskError;

    const { data, error: dbError } = await supabase
      .from("submissions")
      .insert([{ task_id, user_id, status: "pending" }])
      .select()
      .single();

    if (dbError) throw dbError;
    // Store the uploaded file and persist its record with public URL
    const fileRecord = await storeSubmissionFile(data.submission_id, req.file);
    success(res, { submission: data, file: fileRecord });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get submission by ID
const getSubmissionById = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error: dbError } = await supabase
      .from("submissions")
      .select(
        `
        *,
        users!submissions_user_id_fkey(name, email),
        tasks(title, description, posted_by)
      `
      )
      .eq("submission_id", id)
      .single();

    if (dbError) throw dbError;
    success(res, data);
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Update submission status + grade + feedback
const updateSubmissionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, feedback, grade } = req.body;
    if (!["accepted", "rejected", "pending"].includes(status)) {
      return error(res, "invalid status");
    }

    // 1) Update submission
    const { data: sub, error: updErr } = await supabase
      .from("submissions")
      .update({ status, feedback, grade })
      .eq("submission_id", id)
      .select()
      .single();
    if (updErr) throw updErr;

    if (status !== "approved") {
      return success(res, { updated: sub, portfolio: null, edupoints: null });
    }

    // 2) On approve → add to portfolio_entries (if not exists)
    const { data: existing } = await supabase
      .from("portfolio_entries")
      .select("entry_id")
      .eq("submission_id", id)
      .maybeSingle();

    let portfolioEntry = existing;
    if (!existing) {
      const { data: insPE, error: peErr } = await supabase
        .from("portfolio_entries")
        .insert([{ submission_id: id, verified: true }])
        .select()
        .single();
      if (peErr) throw peErr;
      portfolioEntry = insPE;
    }

    // 3) Award EduPoints to the student (simple rule: 100 points)
    const user_id = sub.user_id;
    const { data: edp, error: epErr } = await supabase
      .from("edupoints")
      .insert([{ user_id: user_id, amount: 100, tx_type: "award" }])
      .select()
      .single();
    if (epErr) throw epErr;

    success(res, { updated: sub, portfolio: portfolioEntry, edupoints: edp });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get submissions for a task
const getSubmissionsByTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error: dbError } = await supabase
      .from("submissions")
      .select(
        `
        *,
        users!submissions_user_id_fkey(name, email)
      `
      )
      .eq("task_id", id)
      .order("submit_time", { ascending: false });

    if (dbError) throw dbError;
    success(res, data);
  } catch (e) {
    error(res, e.message, 500);
  }
};

const getFilesForSubmission = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: files, error: dbError } = await supabase
      .from("files")
      .select("*")
      .eq("submission_id", id);

    if (dbError) throw dbError;
    success(res, files);
  } catch (e) {
    error(res, e.message, 500);
  }
};

module.exports = {
  createSubmission,
  getSubmissionById,
  updateSubmissionStatus,
  getSubmissionsByTask,
  getFilesForSubmission,
};
