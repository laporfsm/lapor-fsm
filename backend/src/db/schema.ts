import { pgTable, serial, text, timestamp, boolean, doublePrecision, integer } from 'drizzle-orm/pg-core';

// Users table (Pelapor)
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  ssoId: text('sso_id').unique(), // SSO Undip ID
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  phone: text('phone'),
  faculty: text('faculty').default('Sains dan Matematika'),
  department: text('department'),
  createdAt: timestamp('created_at').defaultNow(),
});

// Staff table (Teknisi, Supervisor, Admin)
export const staff = pgTable('staff', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  phone: text('phone'),
  password: text('password').notNull(), // Hashed password
  role: text('role').notNull(), // 'teknisi', 'supervisor', 'admin'
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
});

// Categories table
export const categories = pgTable('categories', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  type: text('type').notNull(), // 'emergency' or 'non-emergency'
  icon: text('icon'),
});

// Reports table
export const reports = pgTable('reports', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id),
  categoryId: integer('category_id').references(() => categories.id),
  title: text('title').notNull(),
  description: text('description').notNull(),
  building: text('building').notNull(),
  latitude: doublePrecision('latitude'),
  longitude: doublePrecision('longitude'),
  imageUrl: text('image_url'),
  isEmergency: boolean('is_emergency').default(false),
  status: text('status').default('pending'), // pending, verifikasi, penanganan, penanganan_ulang, selesai
  notes: text('notes'),
  // Assignment fields for Teknisi
  assignedTo: integer('assigned_to').references(() => staff.id),
  assignedAt: timestamp('assigned_at'),
  handledAt: timestamp('handled_at'), // When teknisi started handling
  completedAt: timestamp('completed_at'), // When teknisi marked as complete
  handlerNotes: text('handler_notes'), // Notes from teknisi
  handlerMediaUrl: text('handler_media_url'), // Proof photo/video from teknisi
  // Supervisor review
  reviewedBy: integer('reviewed_by').references(() => staff.id),
  reviewedAt: timestamp('reviewed_at'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Report logs for tracking status changes
export const reportLogs = pgTable('report_logs', {
  id: serial('id').primaryKey(),
  reportId: integer('report_id').references(() => reports.id),
  staffId: integer('staff_id').references(() => staff.id),
  action: text('action').notNull(), // 'assigned', 'verified', 'handling', 'completed', 'recalled', 'approved'
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow(),
});

// Type exports
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Staff = typeof staff.$inferSelect;
export type NewStaff = typeof staff.$inferInsert;
export type Report = typeof reports.$inferSelect;
export type NewReport = typeof reports.$inferInsert;
export type Category = typeof categories.$inferSelect;
export type ReportLog = typeof reportLogs.$inferSelect;
export type NewReportLog = typeof reportLogs.$inferInsert;

