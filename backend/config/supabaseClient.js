const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const logger = require("../utils/logger");

// Validate environment variables
if (!process.env.SUPABASE_URL) {
  logger.error("SUPABASE_URL environment variable is missing");
  throw new Error("SUPABASE_URL is required");
}

if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
  logger.error("SUPABASE_SERVICE_ROLE_KEY environment variable is missing");
  throw new Error("SUPABASE_SERVICE_ROLE_KEY is required");
}

logger.info("Initializing Supabase client", {
  url: process.env.SUPABASE_URL.replace(/:[^:]+@/, ":***@"), // Hide password in logs
  hasServiceKey: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
});

// Use SERVICE ROLE KEY for server-side operations
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

// Log client initialization
logger.debug("Supabase client initialized successfully");

// Add logging to common database operations
const originalFrom = supabase.from.bind(supabase);
supabase.from = function (table) {
  logger.logDbOperation("SELECT_FROM", table);
  return originalFrom(table);
};

// Add logging for auth operations
const originalAuth = supabase.auth;
if (originalAuth && originalAuth.getUser) {
  const originalGetUser = originalAuth.getUser.bind(originalAuth);
  originalAuth.getUser = async function (token) {
    logger.logAuth("TOKEN_VALIDATION_ATTEMPT");
    try {
      const result = await originalGetUser(token);
      if (result.error) {
        logger.logAuth("TOKEN_VALIDATION_FAILED", null, false);
        logger.error("Token validation failed", { error: result.error.message });
      } else {
        logger.logAuth("TOKEN_VALIDATION_SUCCESS", result.data.user, true);
      }
      return result;
    } catch (error) {
      logger.logAuth("TOKEN_VALIDATION_ERROR", null, false);
      logger.error("Token validation error", { error: error.message });
      throw error;
    }
  };
}

module.exports = supabase;
