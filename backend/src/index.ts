import { Elysia } from "elysia";
import { cors } from '@elysiajs/cors';
import { staticPlugin } from '@elysiajs/static';
import { reportController } from "./controllers/reporter/report.controller";
import { authController } from "./controllers/auth.controller";
import { uploadController } from "./controllers/upload.controller";
import { staffController } from "./controllers/staff/staff.controller";
import { technicianController } from "./controllers/technician/technician.controller";
import { supervisorController } from "./controllers/supervisor/supervisor.controller";
import { pjController } from "./controllers/staff/pj.controller";
import { adminController } from "./controllers/admin/admin.controller";
import { notificationController } from "./controllers/notification.controller";

const app = new Elysia()
  .use(cors()) // Allow request from Mobile/Web
  .use(staticPlugin({ assets: 'uploads', prefix: '/uploads' })) // Serve uploaded files
  .get("/", () => "Lapor FSM API is Running! 🦊")
  .use(authController)
  .use(reportController)
  .use(uploadController)
  .use(staffController)
  .use(technicianController)
  .use(supervisorController)
  .use(pjController)
  .use(adminController)
  .use(notificationController)
  .listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);

