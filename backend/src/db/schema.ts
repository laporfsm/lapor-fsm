import { pgTable, serial, text, timestamp, boolean, doublePrecision, integer, jsonb } from 'drizzle-orm/pg-core';

// Users table (Pelapor - Students/Staff with SSO)
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

// Staff table (Teknisi, Supervisor, Admin, PJ Gedung)
export const staff = pgTable('staff', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  phone: text('phone'),
  password: text('password').notNull(), // Hashed password
  role: text('role').notNull(), // 'teknisi', 'supervisor', 'admin', 'pj_gedung'
  specialization: text('specialization'), // e.g., 'Kelistrikan', 'Sanitasi'
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
});

// Categories table
export const categories = pgTable('categories', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  type: text('type').notNull(), // 'emergency' or 'non-emergency'
  icon: text('icon'),
  description: text('description'),
});

// Reports table
export const reports = pgTable('reports', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id), // If reported by Pelapor
  staffId: integer('staff_id').references(() => staff.id), // If reported by Staff (e.g. PJ Gedung)
  categoryId: integer('category_id').references(() => categories.id),
  title: text('title').notNull(),
  description: text('description').notNull(),
  building: text('building').notNull(),
  locationDetail: text('location_detail'),
  latitude: doublePrecision('latitude'),
  longitude: doublePrecision('longitude'),
  mediaUrls: jsonb('media_urls').default([]), // List of image URLs
  isEmergency: boolean('is_emergency').default(false),
  status: text('status').default('pending'), 
  // Statuses: pending, verifikasi, terverifikasi, penanganan, diproses, selesai, approved, rejected
  
  // Handling Details
  assignedTo: integer('assigned_to').references(() => staff.id),
  assignedAt: timestamp('assigned_at'),
  handlingStartedAt: timestamp('handling_started_at'),
  handlingCompletedAt: timestamp('handling_completed_at'),
  
  // Technician Result
  handlerNotes: text('handler_notes'),
  handlerMediaUrls: jsonb('handler_media_urls').default([]),
  
  // Verification Details
  verifiedBy: integer('verified_by').references(() => staff.id),
  verifiedAt: timestamp('verified_at'),
  
  // Approval Details
  approvedBy: integer('approved_by').references(() => staff.id),
  approvedAt: timestamp('approved_at'),
  
  // Timestamps
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Report logs for tracking status changes
export const reportLogs = pgTable('report_logs', {
  id: serial('id').primaryKey(),
  reportId: integer('report_id').references(() => reports.id).notNull(),
  actorType: text('actor_type').notNull(), // 'user' or 'staff'
  actorId: integer('actor_id').notNull(),
  action: text('action').notNull(), // 'created', 'verified', 'assigned', 'handling', 'completed', 'approved', 'rejected'
  fromStatus: text('from_status'),
  toStatus: text('to_status'),
  notes: text('notes'),
  mediaUrls: jsonb('media_urls').default([]),
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

