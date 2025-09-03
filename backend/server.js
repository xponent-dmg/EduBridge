const express = require("express");
const cors = require("cors");
require("dotenv").config();

const userRoutes = require("./routes/userRoutes");
const taskRoutes = require("./routes/taskRoutes");
const submissionRoutes = require("./routes/submissionRoutes");
const fileRoutes = require("./routes/fileRoutes");
const portfolioRoutes = require("./routes/portfolioRoutes");
const edupointsRoutes = require("./routes/edupointsRoutes");

const app = express();
app.use(cors());
app.use(express.json());

// Helper functions
function success(res, data) {
  return res.status(200).json({ success: true, data });
}

// Health check endpoint
app.get("/", (_, res) => success(res, { service: "EduBridge API", status: "running" }));

// Routes
app.use("/users", userRoutes);
app.use("/tasks", taskRoutes);
app.use("/submissions", submissionRoutes);
app.use("/files", fileRoutes);
app.use("/portfolio", portfolioRoutes);
app.use("/edupoints", edupointsRoutes);

const PORT = process.env.PORT || 5050;
app.listen(PORT, () => console.log(`EduBridge API running on port ${PORT}`));
