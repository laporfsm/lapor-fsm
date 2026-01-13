import { Elysia } from "elysia";
import { cors } from '@elysiajs/cors';
import { reportController } from "./controllers/reporter/report.controller";

const app = new Elysia()
  .use(cors()) // Allow request from Mobile/Web
  .get("/", () => "Lapor FSM API is Running! 🦊")
  .use(reportController)
  .listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);
