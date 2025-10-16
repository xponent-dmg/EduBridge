const supabase = require("../config/supabaseClient");

// Helper functions
function bad(res, msg, code = 401) {
  return res.status(code).json({ ok: false, error: msg });
}

// Authentication middleware (optional for protected routes)
exports.authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return bad(res, "No token provided", 401);
    }

    const token = authHeader.split(" ")[1];

    // Verify JWT token with Supabase
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error || !user) {
      return bad(res, "Invalid token", 401);
    }

    // Add user to request object
    req.user = user;
    next();
  } catch (e) {
    bad(res, "Authentication failed", 401);
  }
};

// Role-based authorization middleware
exports.authorize = (allowedRoles) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return bad(res, "User not authenticated", 401);
      }

      // Get user role from database
      const { data: userData, error } = await supabase
        .from("User")
        .select("role")
        .eq("email", req.user.email)
        .single();

      if (error || !userData) {
        return bad(res, "User not found", 404);
      }

      if (!allowedRoles.includes(userData.role)) {
        return bad(res, "Insufficient permissions", 403);
      }

      req.userRole = userData.role;
      next();
    } catch (e) {
      bad(res, "Authorization failed", 403);
    }
  };
};
