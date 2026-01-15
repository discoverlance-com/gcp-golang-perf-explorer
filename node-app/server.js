const express = require("express");
const { Firestore } = require("@google-cloud/firestore");
const path = require("path");
const logger = require("./logger");
const pinoHttp = require("pino-http")({ logger });

const app = express();
const port = process.env.PORT || 8080;

app.set("views", path.join(__dirname, "views"));
app.set("view engine", "ejs");

// Use Pino HTTP middleware for request logging
app.use(pinoHttp);

app.use(express.urlencoded({ extended: true }));

app.get("/ping", (req, res) => {
  res.send("I am alive!");
});

// Initialize Firestore
const firestoreOptions = {};
if (process.env.DATABASE_ID) {
  firestoreOptions.databaseId = process.env.DATABASE_ID;
}
const firestore = new Firestore(firestoreOptions);
const collection = firestore.collection("tasks");

// Middleware to record the start time of the request
app.use((req, res, next) => {
  req.startTime = Date.now();
  next();
});

const getDuration = (req) => {
  return Date.now() - req.startTime;
};

// Home route: Lists all tasks
app.get("/", async (req, res) => {
  try {
    const snapshot = await collection.orderBy("created_at", "desc").get();
    const tasks = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Measure time right before rendering
    const duration = getDuration(req);
    res.render("index", { tasks, duration });
  } catch (err) {
    logger.error(err, "Error getting tasks");
    res.status(500).send("Internal Server Error");
  }
});

// Create task route: Input form
app.get("/create", (req, res) => {
  const duration = getDuration(req);
  res.render("create", { duration });
});

// Handle post request to create task
app.post("/create", async (req, res) => {
  try {
    const { title } = req.body;
    if (title) {
      await collection.add({
        title,
        created_at: Date.now(),
      });
      logger.info({ title }, "Task created");
    }
    res.redirect("/");
  } catch (err) {
    logger.error(err, "Error creating task");
    res.status(500).send("Internal Server Error");
  }
});

// Endpoint to delete the task
app.post("/delete/:id", async (req, res) => {
  try {
    const { id } = req.params;
    await collection.doc(id).delete();
    logger.info({ taskId: id }, "Task deleted");
    res.redirect("/");
  } catch (err) {
    logger.error(err, "Error deleting task");
    res.status(500).send("Internal Server Error");
  }
});

app.listen(port, () => {
  logger.info(`Server listening on port ${port}`);
});
