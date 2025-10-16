const supabase = require("../config/supabaseClient");

// Helper functions
function success(res, data) {
  return res.status(200).json({ success: true, data });
}

function error(res, msg, code = 400) {
  return res.status(code).json({ success: false, error: msg });
}

// Redeem points for user
const redeemPoints = async (req, res) => {
  try {
    const { user_id, amount } = req.body;
    if (!user_id || !amount) return error(res, "user_id and amount are required");
    if (amount <= 0) return error(res, "amount must be positive");

    // Verify user exists
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("user_id")
      .eq("user_id", user_id)
      .single();

    if (userError) throw userError;

    // Check if user has enough points
    const { data: transactions, error: txError } = await supabase
      .from("edupoints")
      .select("amount, tx_type")
      .eq("user_id", user_id);

    if (txError) throw txError;

    const totalPoints = transactions.reduce((sum, tx) => {
      return tx.tx_type === "award" ? sum + tx.amount : sum - tx.amount;
    }, 0);

    if (totalPoints < amount) {
      return error(res, "Insufficient points balance");
    }

    const { data: transaction, error: dbError } = await supabase
      .from("edupoints")
      .insert([{ user_id, amount, tx_type: "redeem" }])
      .select()
      .single();

    if (dbError) throw dbError;
    success(res, transaction);
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Get all transactions for a user
const getUserTransactions = async (req, res) => {
  try {
    const { user_id } = req.params;

    const { data: transactions, error: dbError } = await supabase
      .from("edupoints")
      .select("tx_id, user_id, amount, tx_type, tx_time")
      .eq("user_id", user_id)
      .order("tx_time", { ascending: false });

    if (dbError) throw dbError;

    // Calculate balance
    const balance = (transactions || []).reduce((sum, tx) => {
      return tx.tx_type === "award" ? sum + tx.amount : sum - tx.amount;
    }, 0);

    const shaped = (transactions || []).map((tx) => ({
      transaction_id: tx.tx_id,
      user_id: tx.user_id,
      amount: tx.amount,
      description: tx.tx_type === "award" ? "Awarded EduPoints" : "Redeemed EduPoints",
      timestamp: tx.tx_time,
    }));

    success(res, {
      user_id,
      balance,
      transactions: shaped,
      total_awarded: (transactions || [])
        .filter((tx) => tx.tx_type === "award")
        .reduce((sum, tx) => sum + tx.amount, 0),
      total_redeemed: (transactions || [])
        .filter((tx) => tx.tx_type === "redeem")
        .reduce((sum, tx) => sum + tx.amount, 0),
    });
  } catch (e) {
    error(res, e.message, 500);
  }
};

// Award points for user
const awardPoints = async (req, res) => {
  try {
    const { user_id, amount } = req.body;
    if (!user_id || !amount) return error(res, "user_id and amount are required");
    if (amount <= 0) return error(res, "amount must be positive");

    // Verify user exists
    const { error: userError } = await supabase
      .from("users")
      .select("user_id")
      .eq("user_id", user_id)
      .single();
    if (userError) throw userError;

    const { data: transaction, error: dbError } = await supabase
      .from("edupoints")
      .insert([{ user_id, amount, tx_type: "award" }])
      .select()
      .single();
    if (dbError) throw dbError;

    success(res, transaction);
  } catch (e) {
    error(res, e.message, 500);
  }
};

module.exports = {
  redeemPoints,
  getUserTransactions,
  awardPoints,
};
