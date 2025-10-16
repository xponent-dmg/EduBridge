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

    let resolvedUser = user;

    // Fallback: if Supabase reports missing session, try to decode the JWT and lookup via Admin API
    if (!resolvedUser) {
      const errMessage = error?.message || "unknown";
      logger.warn("Primary token validation failed, attempting admin fallback", {
        requestId,
        error: errMessage,
      });

      // Decode JWT payload (no signature verification) to extract claims
      const decodeJwt = (jwt) => {
        try {
          const parts = jwt.split(".");
          if (parts.length !== 3) return null;
          const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
          const pad = "=".repeat((4 - (base64.length % 4)) % 4);
          const json = Buffer.from(base64 + pad, "base64").toString("utf8");
          return JSON.parse(json);
        } catch (e) {
          return null;
        }
      };

      const claims = decodeJwt(token);
      logger.debug("Decoded JWT claims (partial)", {
        requestId,
        hasClaims: !!claims,
        sub: claims?.sub,
        email: claims?.email,
        iss: claims?.iss,
        exp: claims?.exp,
      });

      const nowSec = Math.floor(Date.now() / 1000);
      if (claims && claims.sub && (!claims.exp || claims.exp > nowSec)) {
        try {
          const { data: adminData, error: adminError } = await supabase.auth.admin.getUserById(
            claims.sub
          );
          if (!adminError && adminData?.user) {
            resolvedUser = adminData.user;
            logger.logAuth("AUTHENTICATION_FALLBACK_SUCCESS", resolvedUser, true);
          } else {
            logger.warn("Admin fallback could not resolve user", {
              requestId,
              adminError: adminError?.message,
              sub: claims.sub,
            });
          }
        } catch (e) {
          logger.error("Admin fallback error", { requestId, error: e.message });
        }
      } else {
        logger.warn("JWT claims invalid or expired", {
          requestId,
          hasClaims: !!claims,
          exp: claims?.exp,
          now: nowSec,
        });
      }
    }

    if (!resolvedUser) {
      logger.warn("Authentication failed - Invalid token", {
        requestId,
        error: error?.message,
        hasUser: false,
      });
      return bad(res, "Invalid token", 401);
    }

    logger.logAuth("AUTHENTICATION_SUCCESS", resolvedUser, true);
    logger.debug("User authenticated successfully", {
      requestId,
      userId: resolvedUser.id,
      userEmail: resolvedUser.email,
    });

    // Add user to request object
    req.user = resolvedUser;
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
