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

// Routes
app.use("/api/users", userRoutes);
app.use("/api/tasks", taskRoutes);
app.use("/api/submissions", submissionRoutes);
app.use("/api/files", fileRoutes);
app.use("/api/portfolio", portfolioRoutes);
app.use("/api/edupoints", edupointsRoutes);

const PORT = process.env.PORT || 5050;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
