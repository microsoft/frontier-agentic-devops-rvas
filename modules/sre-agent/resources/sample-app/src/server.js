import http from "node:http";
import { createApp } from "./app.js";

const port = Number.parseInt(process.env.PORT ?? "3000", 10);
const server = http.createServer(createApp());

server.listen(port, () => {
  console.log(`frontier sample app listening on http://localhost:${port}`);
});

process.on("SIGTERM", () => {
  server.close(() => process.exit(0));
});
