const fs = require("fs");
const path = require("path");

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, "..", "logs");
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// Logger utility for debugging
class Logger {
  constructor() {
    this.isDevelopment = process.env.NODE_ENV !== "production";
  }

  formatMessage(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const formattedMessage = `[${timestamp}] [${level}] ${message}`;
    if (data) {
      return `${formattedMessage}\n${JSON.stringify(data, null, 2)}`;
    }
    return formattedMessage;
  }

  log(level, message, data = null) {
    const formattedMessage = this.formatMessage(level, message, data);

    // Always log to console
    console.log(formattedMessage);

    // In production, also write to file
    if (!this.isDevelopment) {
      const logFile = path.join(logsDir, `${new Date().toISOString().split("T")[0]}.log`);
      fs.appendFileSync(logFile, formattedMessage + "\n");
    }
  }

  info(message, data = null) {
    this.log("INFO", message, data);
  }

  debug(message, data = null) {
    this.log("DEBUG", message, data);
  }

  warn(message, data = null) {
    this.log("WARN", message, data);
  }

  error(message, data = null) {
    this.log("ERROR", message, data);
  }

  // Request logging middleware helper
  logRequest(req, res, next) {
    const startTime = Date.now();
    this.debug("REQUEST_START", {
      method: req.method,
      url: req.url,
      ip: req.ip,
      userAgent: req.get("User-Agent"),
    });

    res.on("finish", () => {
      const duration = Date.now() - startTime;
      this.debug("REQUEST_END", {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        duration: `${duration}ms`,
      });
    });

    next();
  }

  // Database operation logging
  logDbOperation(operation, table, data = null) {
    this.debug(`DB_${operation}`, { table, data });
  }

  // Authentication logging
  logAuth(operation, user = null, success = true) {
    this.debug(`AUTH_${operation}`, {
      user: user ? { id: user.id, email: user.email } : null,
      success,
    });
  }

  // File operation logging
  logFileOperation(operation, fileInfo = null) {
    this.debug(`FILE_${operation}`, fileInfo);
  }
}

module.exports = new Logger();
