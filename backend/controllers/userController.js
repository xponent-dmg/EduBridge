const supabase = require("../config/supabaseClient");

// Helper functions - Updated to match specification
function success(res, data) {
  return res.status(200).json({ success: true, data });
}

function error(res, msg, code = 400) {
  return res.status(code).json({ success: false, error: msg });
}

// Create a new user
const createUser = async (req, res) => {
  try {
    const { name, email, role } = req.body;
    if (!name || !email || !role) return error(res, "name, email, role are required");

    // Validate role
    if (!["student", "company"].includes(role)) {
      return error(res, "role must be either 'student' or 'company'");
    }

    const { data, error: dbError } = await supabase
      .from("users")
      .insert([{ name, email, role }])
      .select()
      .single();

    if (dbError) throw dbError;
    success(res, data);
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get all users
const getUsers = async (req, res) => {
  try {
    const { data, error: dbError } = await supabase
      .from("users")
      .select("user_id, name, email, role, created_at")
      .order("created_at", { ascending: false });

    if (dbError) throw dbError;
    success(res, data);
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get user by ID
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("user_id, name, email, role, created_at")
      .eq("user_id", id)
      .single();

    if (userError) throw userError;

    const { data: skillsRows, error: skillsError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (skillsError) throw skillsError;

    const skills = (skillsRows || []).map((row) => row.skill);
    success(res, { ...user, skills });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Update user skills - full replacement
const updateUserSkills = async (req, res) => {
  try {
    const { id } = req.params;
    const { skills } = req.body;

    if (!Array.isArray(skills)) {
      return error(res, "skills must be an array");
    }

    // Remove all existing skills for the user
    const { error: deleteError } = await supabase.from("user_skills").delete().eq("user_id", id);

    if (deleteError) throw deleteError;

    // If no skills provided, return empty list
    if (skills.length === 0) {
      return success(res, { user_id: id, skills: [] });
    }

    // Insert new set of skills
    const rowsToInsert = skills.map((skill) => ({ user_id: id, skill }));
    const { error: insertError } = await supabase.from("user_skills").insert(rowsToInsert);

    if (insertError) throw insertError;

    // Fetch updated list
    const { data: updated, error: fetchError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (fetchError) throw fetchError;
    const updatedSkills = (updated || []).map((row) => row.skill);
    success(res, { user_id: id, skills: updatedSkills });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Add skills to user
const addUserSkills = async (req, res) => {
  try {
    const { id } = req.params;
    const { skills: newSkills } = req.body;

    if (!Array.isArray(newSkills)) {
      return error(res, "skills must be an array");
    }

    // Get current user skills
    const { data: current, error: getUserError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (getUserError) throw getUserError;

    const currentSkills = (current || []).map((row) => row.skill);
    const toAdd = newSkills.filter((s) => !currentSkills.includes(s));

    if (toAdd.length > 0) {
      const rowsToInsert = toAdd.map((skill) => ({ user_id: id, skill }));
      const { error: insertError } = await supabase.from("user_skills").insert(rowsToInsert);
      if (insertError) throw insertError;
    }

    // Fetch updated list
    const { data: updated, error: fetchError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (fetchError) throw fetchError;
    const updatedSkills = (updated || []).map((row) => row.skill);
    success(res, { user_id: id, skills: updatedSkills });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Remove skills from user
const removeUserSkills = async (req, res) => {
  try {
    const { id } = req.params;
    const { skills: skillsToRemove } = req.body;

    if (!Array.isArray(skillsToRemove)) {
      return error(res, "skills must be an array");
    }

    if (skillsToRemove.length > 0) {
      const { error: deleteError } = await supabase
        .from("user_skills")
        .delete()
        .eq("user_id", id)
        .in("skill", skillsToRemove);
      if (deleteError) throw deleteError;
    }

    // Fetch remaining skills
    const { data: remaining, error: fetchError } = await supabase
      .from("user_skills")
      .select("skill")
      .eq("user_id", id);

    if (fetchError) throw fetchError;
    const remainingSkills = (remaining || []).map((row) => row.skill);
    success(res, { user_id: id, skills: remainingSkills });
  } catch (e) {
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
};
