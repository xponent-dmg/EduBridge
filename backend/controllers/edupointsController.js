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

// Redeem points for user
const redeemPoints = async (req, res) => {
  logger.debug("redeemPoints called", {
    bodyKeys: Object.keys(req.body),
    hasUserId: !!req.body.user_id,
    hasAmount: !!req.body.amount,
    amount: req.body.amount,
  });

  try {
    const { user_id, amount } = req.body;
    if (!user_id || !amount) {
      logger.warn("redeemPoints failed - Missing required fields", {
        hasUserId: !!user_id,
        hasAmount: !!amount,
      });
      return error(res, "user_id and amount are required");
    }
    if (amount <= 0) {
      logger.warn("redeemPoints failed - Invalid amount", { amount });
      return error(res, "amount must be positive");
    }

    logger.debug("Verifying user exists", { userId: user_id });
    // Verify user exists
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("user_id")
      .eq("user_id", user_id)
      .single();

    if (userError) {
      logger.error("Failed to verify user exists", { userId: user_id, error: userError.message });
      throw userError;
    }

    logger.debug("Calculating user points balance", { userId: user_id });
    // Check if user has enough points
    const { data: transactions, error: txError } = await supabase
      .from("edupoints")
      .select("amount, tx_type")
      .eq("user_id", user_id);

    if (txError) {
      logger.error("Failed to fetch user transactions", {
        userId: user_id,
        error: txError.message,
      });
      throw txError;
    }

    const totalPoints = transactions.reduce((sum, tx) => {
      return tx.tx_type === "award" ? sum + tx.amount : sum - tx.amount;
    }, 0);

    logger.debug("Points balance calculated", {
      userId: user_id,
      balance: totalPoints,
      requestedAmount: amount,
    });

    if (totalPoints < amount) {
      logger.warn("redeemPoints failed - Insufficient balance", {
        userId: user_id,
        balance: totalPoints,
        requested: amount,
      });
      return error(res, "Insufficient points balance");
    }

    logger.debug("Creating redeem transaction", { userId: user_id, amount });
    const { data: transaction, error: dbError } = await supabase
      .from("edupoints")
      .insert([{ user_id, amount, tx_type: "redeem" }])
      .select()
      .single();

    if (dbError) {
      logger.error("Failed to create redeem transaction", {
        userId: user_id,
        error: dbError.message,
      });
      throw dbError;
    }

    logger.info("Points redeemed successfully", {
      userId: user_id,
      amount,
      transactionId: transaction.tx_id,
    });
    success(res, transaction);
  } catch (e) {
    logger.error("redeemPoints error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

// Get all transactions for a user
const getUserTransactions = async (req, res) => {
  const { user_id } = req.params;
  logger.debug("getUserTransactions called", { userId: user_id });

  try {
    logger.debug("Fetching transactions for user", { userId: user_id });
    const { data: transactions, error: dbError } = await supabase
      .from("edupoints")
      .select("tx_id, user_id, amount, tx_type, tx_time")
      .eq("user_id", user_id)
      .order("tx_time", { ascending: false });

    if (dbError) {
      logger.error("Failed to fetch user transactions", {
        userId: user_id,
        error: dbError.message,
      });
      throw dbError;
    }

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

    const totalAwarded = (transactions || [])
      .filter((tx) => tx.tx_type === "award")
      .reduce((sum, tx) => sum + tx.amount, 0);

    const totalRedeemed = (transactions || [])
      .filter((tx) => tx.tx_type === "redeem")
      .reduce((sum, tx) => sum + tx.amount, 0);

    logger.debug("getUserTransactions completed successfully", {
      userId: user_id,
      transactionsCount: shaped.length,
      balance,
      totalAwarded,
      totalRedeemed,
    });

    success(res, {
      user_id,
      balance,
      transactions: shaped,
      total_awarded: totalAwarded,
      total_redeemed: totalRedeemed,
    });
  } catch (e) {
    logger.error("getUserTransactions error", {
      userId: user_id,
      error: e.message,
      stack: e.stack,
    });
    error(res, e.message, 500);
  }
};

// Award points for user
const awardPoints = async (req, res) => {
  logger.debug("awardPoints called", {
    bodyKeys: Object.keys(req.body),
    hasUserId: !!req.body.user_id,
    hasAmount: !!req.body.amount,
    amount: req.body.amount,
  });

  try {
    const { user_id, amount } = req.body;
    if (!user_id || !amount) {
      logger.warn("awardPoints failed - Missing required fields", {
        hasUserId: !!user_id,
        hasAmount: !!amount,
      });
      return error(res, "user_id and amount are required");
    }
    if (amount <= 0) {
      logger.warn("awardPoints failed - Invalid amount", { amount });
      return error(res, "amount must be positive");
    }

    logger.debug("Verifying user exists", { userId: user_id });
    // Verify user exists
    const { error: userError } = await supabase
      .from("users")
      .select("user_id")
      .eq("user_id", user_id)
      .single();
    if (userError) {
      logger.error("Failed to verify user exists", { userId: user_id, error: userError.message });
      throw userError;
    }

    logger.debug("Creating award transaction", { userId: user_id, amount });
    const { data: transaction, error: dbError } = await supabase
      .from("edupoints")
      .insert([{ user_id, amount, tx_type: "award" }])
      .select()
      .single();
    if (dbError) {
      logger.error("Failed to create award transaction", {
        userId: user_id,
        error: dbError.message,
      });
      throw dbError;
    }

    logger.info("Points awarded successfully", {
      userId: user_id,
      amount,
      transactionId: transaction.tx_id,
    });
    success(res, transaction);
  } catch (e) {
    logger.error("awardPoints error", { error: e.message, stack: e.stack });
    error(res, e.message, 500);
  }
};

module.exports = {
  redeemPoints,
  getUserTransactions,
  awardPoints,
};
