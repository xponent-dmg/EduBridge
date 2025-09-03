const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

// Use SERVICE ROLE KEY for server-side operations
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

module.exports = supabase;
