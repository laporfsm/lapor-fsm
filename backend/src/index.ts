import { Elysia } from "elysia";
import { cors } from '@elysiajs/cors';
import { staticPlugin } from '@elysiajs/static';
import { reportController } from "./controllers/reporter/report.controller";
import { authController } from "./controllers/auth.controller";
import { uploadController } from "./controllers/upload.controller";

const app = new Elysia()
  .use(cors()) // Allow request from Mobile/Web
  .use(staticPlugin({ assets: 'uploads', prefix: '/uploads' })) // Serve uploaded files
  .get("/", () => "Lapor FSM API is Running! 🦊")
  .use(authController)
  .use(reportController)
  .use(uploadController)
  .listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);
