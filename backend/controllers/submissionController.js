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

// Internal: store an uploaded file for a submission and persist its DB record
async function storeSubmissionFile(submissionId, file) {
  logger.debug("storeSubmissionFile called", { submissionId, hasFile: !!file });

  if (!file) {
    logger.error("storeSubmissionFile failed - file is required");
    throw new Error("file is required");
  }

  const bucket = process.env.SUPABASE_SUBMISSIONS_BUCKET;
  if (!bucket) {
    logger.error("SUPABASE_SUBMISSIONS_BUCKET is not configured");
    throw new Error("SUPABASE_SUBMISSIONS_BUCKET is not configured");
  }

  const fileBuffer = file.buffer;
  const fileType = file.mimetype || "application/octet-stream";
  const originalName = file.originalname || "upload.bin";
  const objectPath = `submissions/${submissionId}/${Date.now()}_${originalName}`;

  logger.logFileOperation("UPLOAD_START", {
    submissionId,
    bucket,
    fileName: originalName,
    fileType,
    fileSize: fileBuffer?.length,
  });

  try {
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(objectPath, fileBuffer, { contentType: fileType, upsert: false });
    if (uploadError) {
      logger.error("File upload failed", { submissionId, objectPath, error: uploadError.message });
      throw uploadError;
    }

    logger.logFileOperation("UPLOAD_SUCCESS", { submissionId, objectPath });

    const { data: publicUrlData } = supabase.storage.from(bucket).getPublicUrl(objectPath);
    const publicUrl = publicUrlData?.publicUrl || null;

    logger.debug("Creating file record in database", { submissionId, objectPath });
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
    if (fileInsertError) {
      logger.error("Failed to create file record", {
        submissionId,
        error: fileInsertError.message,
      });
      throw fileInsertError;
    }

    logger.logFileOperation("FILE_RECORD_CREATED", { submissionId, fileId: fileRecord.file_id });
    return fileRecord;
  } catch (error) {
    logger.error("storeSubmissionFile error", { submissionId, error: error.message });
    throw error;
  }
}

// Create submission
const createSubmission = async (req, res) => {
  logger.debug("createSubmission called", {
    bodyKeys: Object.keys(req.body),
    hasTaskId: !!req.body.task_id,
    hasFile: !!req.file,
  });

  try {
    const { task_id } = req.body;
    const authUserId = req.user?.id;
    if (!task_id) {
      logger.warn("createSubmission failed - Missing required fields", {
        hasTaskId: !!task_id,
      });
      return error(res, "task_id is required");
    }
    if (!req.file) {
      logger.warn("createSubmission failed - No file provided");
      return error(res, "file is required");
    }

    if (!authUserId) {
      logger.warn("createSubmission failed - Not authenticated or missing user in request context");
      return error(res, "Not authenticated", 401);
    }

    logger.debug("Verifying task exists", { taskId: task_id });
    // Verify task exists
    const { data: task, error: taskError } = await supabase
      .from("tasks")
      .select("task_id")
      .eq("task_id", task_id)
      .single();

    if (taskError) {
      logger.error("Failed to verify task", { taskId: task_id, error: taskError.message });
      throw taskError;
    }

    logger.debug("Creating submission record", { taskId: task_id, userId: authUserId });
    const { data, error: dbError } = await supabase
      .from("submissions")
      .insert([{ task_id, user_id: authUserId, status: "pending" }])
      .select()
      .single();

    if (dbError) {
      logger.error("Failed to create submission", {
        taskId: task_id,
        error: dbError.message,
      });
      throw dbError;
    }

    logger.debug("Storing uploaded file", { submissionId: data.submission_id });
    // Store the uploaded file and persist its record with public URL
    const fileRecord = await storeSubmissionFile(data.submission_id, req.file);

    logger.info("Submission created successfully", {
      submissionId: data.submission_id,
      taskId: task_id,
      fileId: fileRecord.file_id,
    });

    success(res, { submission: data, file: fileRecord });
  } catch (e) {
    logger.error("createSubmission error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Get submission by ID
const getSubmissionById = async (req, res) => {
  const { id } = req.params;
  logger.debug("getSubmissionById called", { submissionId: id });

  try {
    logger.debug("Fetching submission by ID", { submissionId: id });
    const { data, error: dbError } = await supabase
      .from("submissions")
      .select(
        `
        *,
        tasks(title, description, posted_by)
      `
      )
      .eq("submission_id", id)
      .single();

    if (dbError) {
      logger.error("Failed to fetch submission", { submissionId: id, error: dbError.message });
      throw dbError;
    }

    logger.debug("getSubmissionById completed successfully", { submissionId: id });
    success(res, data);
  } catch (e) {
    logger.error("getSubmissionById error", { submissionId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Update submission status + grade + feedback
const updateSubmissionStatus = async (req, res) => {
  const { id } = req.params;
  const { status, feedback, grade } = req.body;
  logger.debug("updateSubmissionStatus called", {
    submissionId: id,
    status,
    hasFeedback: !!feedback,
    hasGrade: !!grade,
  });

  try {
    if (!["accepted", "rejected", "pending"].includes(status)) {
      logger.warn("updateSubmissionStatus failed - invalid status", {
        status,
        validStatuses: ["accepted", "rejected", "pending"],
      });
      return error(res, "invalid status");
    }

    logger.debug("Updating submission status", { submissionId: id, status, grade });
    // 1) Update submission
    const { data: sub, error: updErr } = await supabase
      .from("submissions")
      .update({ status, feedback, grade })
      .eq("submission_id", id)
      .select()
      .single();
    if (updErr) {
      logger.error("Failed to update submission", { submissionId: id, error: updErr.message });
      throw updErr;
    }

    if (status !== "accepted") {
      logger.debug("Submission not accepted, returning without portfolio", {
        submissionId: id,
        status,
      });
      return success(res, { updated: sub, portfolio: null });
    }

    // 2) On approve → add to portfolio_entries (if not exists) ONLY when grade >= 80
    const effectiveGrade = typeof sub?.grade === "number" ? sub.grade : Number(grade);
    if (!(effectiveGrade >= 80)) {
      logger.debug("Accepted but below portfolio threshold; skipping portfolio add", {
        submissionId: id,
        grade: effectiveGrade,
      });
      return success(res, { updated: sub, portfolio: null });
    }

    // Add to portfolio if above threshold
    logger.debug("Checking for existing portfolio entry", { submissionId: id });
    const { data: existing } = await supabase
      .from("portfolio_entries")
      .select("entry_id")
      .eq("submission_id", id)
      .maybeSingle();

    let portfolioEntry = existing;
    if (!existing) {
      logger.debug("Creating portfolio entry", { submissionId: id });
      const { data: insPE, error: peErr } = await supabase
        .from("portfolio_entries")
        .insert([{ submission_id: id, verified: true }])
        .select()
        .single();
      if (peErr) {
        logger.error("Failed to create portfolio entry", {
          submissionId: id,
          error: peErr.message,
        });
        throw peErr;
      }
      portfolioEntry = insPE;
      logger.debug("Portfolio entry created", { portfolioEntryId: portfolioEntry.entry_id });
    } else {
      logger.debug("Portfolio entry already exists", { portfolioEntryId: existing.entry_id });
    }

    logger.info("Submission approved successfully", {
      submissionId: id,
      portfolioEntryId: portfolioEntry?.entry_id,
    });

    success(res, { updated: sub, portfolio: portfolioEntry });
  } catch (e) {
    logger.error("updateSubmissionStatus error", {
      submissionId: id,
      error: e.message,
      stack: e.stack,
    });
    error(res, e.message, 500);
  }
};

// Get submissions for a task
const getSubmissionsByTask = async (req, res) => {
  const { id } = req.params;
  logger.debug("getSubmissionsByTask called", { taskId: id });

  try {
    logger.debug("Fetching submissions for task", { taskId: id });
    const { data, error: dbError } = await supabase
      .from("submissions")
      .select("*")
      .eq("task_id", id)
      .order("submit_time", { ascending: false });

    if (dbError) {
      logger.error("Failed to fetch submissions for task", { taskId: id, error: dbError.message });
      throw dbError;
    }

    // Shape submit_time -> submitted_at for frontend
    const shaped = (data || []).map((s) => ({ ...s, submitted_at: s.submit_time }));
    logger.debug("getSubmissionsByTask completed successfully", {
      taskId: id,
      submissionsCount: shaped.length,
    });

    success(res, shaped);
  } catch (e) {
    logger.error("getSubmissionsByTask error", { taskId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

const getFilesForSubmission = async (req, res) => {
  const { id } = req.params;
  logger.debug("getFilesForSubmission called", { submissionId: id });

  try {
    logger.debug("Fetching files for submission", { submissionId: id });
    const { data: files, error: dbError } = await supabase
      .from("files")
      .select("*")
      .eq("submission_id", id);

    if (dbError) {
      logger.error("Failed to fetch files for submission", {
        submissionId: id,
        error: dbError.message,
      });
      throw dbError;
    }

    logger.debug("getFilesForSubmission completed successfully", {
      submissionId: id,
      filesCount: (files || []).length,
    });
    success(res, files);
  } catch (e) {
    logger.error("getFilesForSubmission error", {
      submissionId: id,
      error: e.message,
      stack: e.stack,
    });
    error(res, e.message, 500);
  }
};

// Get submissions for a user
const getSubmissionsByUser = async (req, res) => {
  const { id } = req.params;
  logger.debug("getSubmissionsByUser called", { userId: id });

  try {
    // Fetch submissions for this user
    const { data, error: dbError } = await supabase
      .from("submissions")
      .select("*")
      .eq("user_id", id);

    if (dbError) {
      logger.error("Supabase query failed", { error: dbError.message });
      return error(res, "Database query failed", 500);
    }

    const shaped = (data || []).map((s) => ({ ...s, submitted_at: s.submit_time }));

    logger.info("Fetched submissions for user", { userId: id, count: shaped.length });
    return success(res, shaped);
  } catch (e) {
    logger.error("getSubmissionsByUser error", {
      userId: id,
      error: e.message,
      stack: e.stack,
    });
    return error(res, e.message, 500);
  }
};

// Update only grade and feedback for a submission
const updateSubmissionGrade = async (req, res) => {
  const { id } = req.params;
  const { grade, feedback } = req.body;
  logger.debug("updateSubmissionGrade called", {
    submissionId: id,
    hasGrade: !!grade,
    hasFeedback: !!feedback,
  });

  try {
    logger.debug("Updating submission grade/feedback and deriving status", {
      submissionId: id,
      grade,
      feedback,
    });

    // Determine status from grade (>=60 => accepted, else rejected)
    const numericGrade = Number(grade);
    const derivedStatus =
      Number.isFinite(numericGrade) && numericGrade >= 60 ? "accepted" : "rejected";

    const { data: sub, error: updErr } = await supabase
      .from("submissions")
      .update({ grade: numericGrade, feedback, status: derivedStatus })
      .eq("submission_id", id)
      .select()
      .single();

    if (updErr) {
      logger.error("Failed to update submission grade", {
        submissionId: id,
        error: updErr.message,
      });
      throw updErr;
    }

    // If accepted and grade >= 80, ensure portfolio entry exists
    if (derivedStatus === "accepted" && numericGrade >= 80) {
      logger.debug("Grade meets portfolio threshold; ensuring portfolio entry", {
        submissionId: id,
        numericGrade,
      });
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
        if (peErr) {
          logger.error("Failed to create portfolio entry after grading", {
            submissionId: id,
            error: peErr.message,
          });
          throw peErr;
        }
        portfolioEntry = insPE;
        logger.debug("Portfolio entry created after grading", {
          portfolioEntryId: portfolioEntry.entry_id,
        });
      } else {
        logger.debug("Portfolio entry already exists after grading", {
          portfolioEntryId: existing.entry_id,
        });
      }
      logger.debug("updateSubmissionGrade completed with portfolio", { submissionId: id });
      success(res, { updated: sub, portfolio: portfolioEntry });
      return;
    }

    logger.debug("updateSubmissionGrade completed (no portfolio)", { submissionId: id });
    success(res, { updated: sub, portfolio: null });
  } catch (e) {
    logger.error("updateSubmissionGrade error", {
      submissionId: id,
      error: e.message,
      stack: e.stack,
    });
    error(res, e.message, 500);
  }
};

module.exports = {
  createSubmission,
  getSubmissionById,
  updateSubmissionStatus,
  getSubmissionsByTask,
  getFilesForSubmission,
  getSubmissionsByUser,
  updateSubmissionGrade,
};
