const supabase = require("../config/supabaseClient");
const logger = require("../utils/logger");

// Helper functions
function bad(res, msg, code = 401) {
  logger.warn("Authentication failed", { message: msg, statusCode: code });
  return res.status(code).json({ ok: false, error: msg });
}

// Authentication middleware (optional for protected routes)
exports.authenticate = async (req, res, next) => {
  const requestId = `${req.method} ${req.path} - ${Date.now()}`;
  logger.debug("Authentication middleware started", {
    requestId,
    method: req.method,
    path: req.path,
    hasAuthHeader: !!req.headers.authorization,
  });

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      logger.warn("Authentication failed - No token provided", {
        requestId,
        method: req.method,
        path: req.path,
      });
      return bad(res, "No token provided", 401);
    }

    const token = authHeader.split(" ")[1];
    logger.debug("Token extracted from header", { requestId, tokenLength: token.length });

    // Verify JWT token with Supabase
    logger.debug("Verifying JWT token with Supabase", { requestId });
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error || !user) {
      logger.warn("Authentication failed - Invalid token", {
        requestId,
        error: error?.message,
        hasUser: !!user,
      });
      return bad(res, "Invalid token", 401);
    }

    logger.logAuth("AUTHENTICATION_SUCCESS", user, true);
    logger.debug("User authenticated successfully", {
      requestId,
      userId: user.id,
      userEmail: user.email,
    });

    // Add user to request object
    req.user = user;
    next();
  } catch (e) {
    logger.error("Authentication middleware error", {
      requestId,
      error: e.message,
      stack: e.stack,
    });
    bad(res, "Authentication failed", 401);
  }
};

// Role-based authorization middleware
exports.authorize = (allowedRoles) => {
  logger.debug("Authorization middleware created", { allowedRoles });
  return async (req, res, next) => {
    const requestId = `${req.method} ${req.path} - ${Date.now()}`;
    logger.debug("Authorization middleware started", {
      requestId,
      method: req.method,
      path: req.path,
      allowedRoles,
      hasUser: !!req.user,
    });

    try {
      if (!req.user) {
        logger.warn("Authorization failed - User not authenticated", { requestId });
        return bad(res, "User not authenticated", 401);
      }

      logger.debug("Fetching user role from database", {
        requestId,
        userEmail: req.user.email,
      });

      // Get user role from database
      const { data: userData, error } = await supabase
        .from("users")
        .select("role")
        .eq("email", req.user.email)
        .single();

      if (error || !userData) {
        logger.warn("Authorization failed - User not found in database", {
          requestId,
          error: error?.message,
          userEmail: req.user.email,
        });
        return bad(res, "User not found", 404);
      }

      logger.debug("User role retrieved", {
        requestId,
        userEmail: req.user.email,
        userRole: userData.role,
      });

      if (!allowedRoles.includes(userData.role)) {
        logger.warn("Authorization failed - Insufficient permissions", {
          requestId,
          userEmail: req.user.email,
          userRole: userData.role,
          allowedRoles,
          requiredRoles: allowedRoles,
        });
        return bad(res, "Insufficient permissions", 403);
      }

      logger.logAuth("AUTHORIZATION_SUCCESS", req.user, true);
      logger.debug("User authorized successfully", {
        requestId,
        userEmail: req.user.email,
        userRole: userData.role,
        allowedRoles,
      });

      req.userRole = userData.role;
      next();
    } catch (e) {
      logger.error("Authorization middleware error", {
        requestId,
        error: e.message,
        stack: e.stack,
      });
      bad(res, "Authorization failed", 403);
    }
  };
};
