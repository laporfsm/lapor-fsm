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
import { categoryController } from "./controllers/admin/category.controller";
import { locationController } from "./controllers/supervisor/location.controller";
import { specializationController } from "./controllers/supervisor/specialization.controller";
import { trackingController } from "./controllers/emergency/tracking.controller";

const app = new Elysia()
  .onError(({ code, error, set }) => {
    console.error(`[API ERROR] ${code}:`, error);

    if (code === 'VALIDATION') {
      set.status = 400;
      return { status: 'error', message: 'Validasi input gagal', details: error.all };
    }

    if (code === 'NOT_FOUND') {
      set.status = 404;
      return { status: 'error', message: 'Endpoint tidak ditemukan' };
    }

    set.status = 500;
    return { status: 'error', message: 'Terjadi kesalahan sistem internal' };
  })
  .use(cors({
    origin: true, // Allow all origins (for development)
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  })) // Allow request from Mobile/Web
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
  .use(categoryController)
  .use(locationController)
  .use(specializationController)
  .use(trackingController)
  .listen({
    port: process.env.PORT || 3000,
    hostname: '0.0.0.0'
  });

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);

