const supabase = require("../config/supabaseClient");
const logger = require("../utils/logger");

// Helper functions - Updated to match specification
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

// Get current authenticated user (based on Supabase JWT)
const getMe = async (req, res) => {
  logger.debug("getMe called", { userId: req.user?.id, userEmail: req.user?.email });

  try {
    const supaUser = req.user;
    if (!supaUser || !supaUser.email) {
      logger.warn("getMe failed - Not authenticated", { hasUser: !!supaUser });
      return error(res, "Not authenticated", 401);
    }

    logger.debug("Looking up application user by email", { email: supaUser.email });

    // Lookup the application user by email
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("user_id, name, email, role, created_at")
      .eq("email", supaUser.email)
      .single();

    if (userError) {
      logger.error("Failed to lookup user by email", {
        email: supaUser.email,
        error: userError.message,
      });
      throw userError;
    }

    logger.debug("User found, fetching skills", { userId: user.user_id });

    // Fetch skills for the user
    const { data: skillsRows, error: skillsError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", user.user_id);

    if (skillsError) {
      logger.error("Failed to fetch user skills", {
        userId: user.user_id,
        error: skillsError.message,
      });
      throw skillsError;
    }

    const skills = (skillsRows || []).map((row) => row.skill);
    logger.debug("getMe completed successfully", {
      userId: user.user_id,
      skillsCount: skills.length,
    });

    success(res, { ...user, skills });
  } catch (e) {
    logger.error("getMe error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Create a new user
const createUser = async (req, res) => {
  logger.debug("createUser called", {
    bodyKeys: Object.keys(req.body),
    hasName: !!req.body.name,
    hasEmail: !!req.body.email,
    hasRole: !!req.body.role,
  });

  try {
    const { name, email, role } = req.body;
    if (!name || !email || !role) {
      logger.warn("createUser failed - Missing required fields", {
        name: !!name,
        email: !!email,
        role: !!role,
      });
      return error(res, "name, email, role are required");
    }

    // Validate role
    if (!["student", "company"].includes(role)) {
      logger.warn("createUser failed - Invalid role", { role, validRoles: ["student", "company"] });
      return error(res, "role must be either 'student' or 'company'");
    }

    logger.debug("Creating user in database", { name, email, role });

    const { data, error: dbError } = await supabase
      .from("users")
      .insert([{ name, email, role }])
      .select()
      .single();

    if (dbError) {
      logger.error("Failed to create user in database", {
        name,
        email,
        role,
        error: dbError.message,
      });
      throw dbError;
    }

    logger.info("User created successfully", { userId: data.user_id, name, email, role });
    success(res, data);
  } catch (e) {
    logger.error("createUser error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Get all users
const getUsers = async (req, res) => {
  logger.debug("getUsers called");

  try {
    logger.debug("Fetching all users from database");
    const { data, error: dbError } = await supabase
      .from("users")
      .select("user_id, name, email, role, created_at")
      .order("created_at", { ascending: false });

    if (dbError) {
      logger.error("Failed to fetch users", { error: dbError.message });
      throw dbError;
    }

    logger.debug("getUsers completed successfully", { userCount: (data || []).length });
    success(res, data);
  } catch (e) {
    logger.error("getUsers error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Get user by ID
const getUserById = async (req, res) => {
  const { id } = req.params;
  logger.debug("getUserById called", { userId: id });

  try {
    logger.debug("Fetching user by ID", { userId: id });
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("user_id, name, email, role, created_at")
      .eq("user_id", id)
      .single();

    if (userError) {
      logger.error("Failed to fetch user by ID", { userId: id, error: userError.message });
      throw userError;
    }

    logger.debug("User found, fetching skills", { userId: id });
    const { data: skillsRows, error: skillsError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (skillsError) {
      logger.error("Failed to fetch user skills", { userId: id, error: skillsError.message });
      throw skillsError;
    }

    const skills = (skillsRows || []).map((row) => row.skill);
    logger.debug("getUserById completed successfully", { userId: id, skillsCount: skills.length });

    success(res, { ...user, skills });
  } catch (e) {
    logger.error("getUserById error", { userId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Update user skills - full replacement
const updateUserSkills = async (req, res) => {
  const { id } = req.params;
  const { skills } = req.body;
  logger.debug("updateUserSkills called", { userId: id, skillsCount: skills?.length });

  try {
    if (!Array.isArray(skills)) {
      logger.warn("updateUserSkills failed - skills not array", { skillsType: typeof skills });
      return error(res, "skills must be an array");
    }

    logger.debug("Removing existing skills for user", { userId: id });
    // Remove all existing skills for the user
    const { error: deleteError } = await supabase.from("user_skills").delete().eq("user_id", id);

    if (deleteError) {
      logger.error("Failed to remove existing skills", { userId: id, error: deleteError.message });
      throw deleteError;
    }

    // If no skills provided, return empty list
    if (skills.length === 0) {
      logger.debug("No skills provided, returning empty list", { userId: id });
      return success(res, { user_id: id, skills: [] });
    }

    logger.debug("Inserting new skills for user", { userId: id, skillsCount: skills.length });
    // Insert new set of skills
    const rowsToInsert = skills.map((skill) => ({ user_id: id, skill }));
    const { error: insertError } = await supabase.from("user_skills").insert(rowsToInsert);

    if (insertError) {
      logger.error("Failed to insert new skills", { userId: id, error: insertError.message });
      throw insertError;
    }

    // Fetch updated list
    logger.debug("Fetching updated skills list", { userId: id });
    const { data: updated, error: fetchError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (fetchError) {
      logger.error("Failed to fetch updated skills", { userId: id, error: fetchError.message });
      throw fetchError;
    }

    const updatedSkills = (updated || []).map((row) => row.skill);
    logger.debug("updateUserSkills completed successfully", {
      userId: id,
      skillsCount: updatedSkills.length,
    });

    success(res, { user_id: id, skills: updatedSkills });
  } catch (e) {
    logger.error("updateUserSkills error", { userId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Add skills to user
const addUserSkills = async (req, res) => {
  const { id } = req.params;
  const { skills: newSkills } = req.body;
  logger.debug("addUserSkills called", { userId: id, newSkillsCount: newSkills?.length });

  try {
    if (!Array.isArray(newSkills)) {
      logger.warn("addUserSkills failed - skills not array", { skillsType: typeof newSkills });
      return error(res, "skills must be an array");
    }

    logger.debug("Fetching current user skills", { userId: id });
    // Get current user skills
    const { data: current, error: getUserError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (getUserError) {
      logger.error("Failed to fetch current skills", { userId: id, error: getUserError.message });
      throw getUserError;
    }

    const currentSkills = (current || []).map((row) => row.skill);
    const toAdd = newSkills.filter((s) => !currentSkills.includes(s));

    logger.debug("Filtered skills to add", {
      userId: id,
      currentSkillsCount: currentSkills.length,
      toAddCount: toAdd.length,
    });

    if (toAdd.length > 0) {
      logger.debug("Inserting new skills", { userId: id, skillsToAdd: toAdd });
      const rowsToInsert = toAdd.map((skill) => ({ user_id: id, skill }));
      const { error: insertError } = await supabase.from("user_skills").insert(rowsToInsert);
      if (insertError) {
        logger.error("Failed to insert new skills", { userId: id, error: insertError.message });
        throw insertError;
      }
    } else {
      logger.debug("No new skills to add", { userId: id });
    }

    // Fetch updated list
    logger.debug("Fetching updated skills list", { userId: id });
    const { data: updated, error: fetchError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (fetchError) {
      logger.error("Failed to fetch updated skills", { userId: id, error: fetchError.message });
      throw fetchError;
    }

    const updatedSkills = (updated || []).map((row) => row.skill);
    logger.debug("addUserSkills completed successfully", {
      userId: id,
      skillsCount: updatedSkills.length,
    });

    success(res, { user_id: id, skills: updatedSkills });
  } catch (e) {
    logger.error("addUserSkills error", { userId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Remove skills from user
const removeUserSkills = async (req, res) => {
  const { id } = req.params;
  const { skills: skillsToRemove } = req.body;
  logger.debug("removeUserSkills called", {
    userId: id,
    skillsToRemoveCount: skillsToRemove?.length,
  });

  try {
    if (!Array.isArray(skillsToRemove)) {
      logger.warn("removeUserSkills failed - skills not array", {
        skillsType: typeof skillsToRemove,
      });
      return error(res, "skills must be an array");
    }

    if (skillsToRemove.length > 0) {
      logger.debug("Removing skills from user", { userId: id, skillsToRemove });
      const { error: deleteError } = await supabase
        .from("user_skills")
        .delete()
        .eq("user_id", id)
        .in("skill", skillsToRemove);
      if (deleteError) {
        logger.error("Failed to remove skills", { userId: id, error: deleteError.message });
        throw deleteError;
      }
    } else {
      logger.debug("No skills to remove", { userId: id });
    }

    // Fetch remaining skills
    logger.debug("Fetching remaining skills", { userId: id });
    const { data: remaining, error: fetchError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (fetchError) {
      logger.error("Failed to fetch remaining skills", { userId: id, error: fetchError.message });
      throw fetchError;
    }

    const remainingSkills = (remaining || []).map((row) => row.skill);
    logger.debug("removeUserSkills completed successfully", {
      userId: id,
      remainingSkillsCount: remainingSkills.length,
    });

    success(res, { user_id: id, skills: remainingSkills });
  } catch (e) {
    logger.error("removeUserSkills error", { userId: id, error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

module.exports = {
  createUser,
  getUsers,
  getUserById,
  updateUserSkills,
  addUserSkills,
  removeUserSkills,
  getMe,
};
