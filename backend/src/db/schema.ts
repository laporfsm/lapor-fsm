import { pgTable, serial, text, timestamp, boolean, doublePrecision, integer, jsonb } from 'drizzle-orm/pg-core';

// Users table (Pelapor)
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  password: text('password').notNull(), // Hashed password
  phone: text('phone'),
  nimNip: text('nim_nip'),
  department: text('department'),
  faculty: text('faculty').default('Sains dan Matematika'),
  address: text('address'),
  emergencyName: text('emergency_name'),
  emergencyPhone: text('emergency_phone'),
  idCardUrl: text('id_card_url'), // For non-undip users
  fcmToken: text('fcm_token'),
  isVerified: boolean('is_verified').default(false), // Admin verification
  isEmailVerified: boolean('is_email_verified').default(false),
  emailVerificationToken: text('email_verification_token'),
  emailVerificationExpiresAt: timestamp('email_verification_expires_at'),
  passwordResetToken: text('password_reset_token'),
  passwordResetExpiresAt: timestamp('password_reset_expires_at'),
  isActive: boolean('is_active').default(true), // Admin suspension
  createdAt: timestamp('created_at').defaultNow(),
});

// Staff table (Teknisi, Supervisor, Admin, PJ Gedung)
export const staff = pgTable('staff', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  phone: text('phone'),
  address: text('address'),
  fcmToken: text('fcm_token'),
  password: text('password').notNull(), // Hashed password
  role: text('role').notNull(), // 'teknisi', 'supervisor', 'admin', 'pj_gedung'
  specialization: text('specialization'), // e.g., 'Kelistrikan', 'Sanitasi'
  isActive: boolean('is_active').default(true),
  managedBuilding: text('managed_building'), // Specific for PJ Gedung
  createdAt: timestamp('created_at').defaultNow(),
});

// Buildings table
export const buildings = pgTable('buildings', {
  id: serial('id').primaryKey(),
  name: text('name').notNull().unique(),
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
  parentId: integer('parent_id'), // Self-reference for grouped reports
  userId: integer('user_id').references(() => users.id),
  staffId: integer('staff_id').references(() => staff.id),
  categoryId: integer('category_id').references(() => categories.id),
  title: text('title').notNull(),
  description: text('description').notNull(),
  building: text('building').notNull(),
  locationDetail: text('location_detail'),
  latitude: doublePrecision('latitude'),
  longitude: doublePrecision('longitude'),
  mediaUrls: jsonb('media_urls').default([]),
  isEmergency: boolean('is_emergency').default(false),
  status: text('status').default('pending'),
  // Mobile Enum: pending, terverifikasi, verifikasi, penanganan, onHold, selesai, approved, ditolak, recalled, archived

  // Handling Details
  assignedTo: integer('assigned_to').references(() => staff.id),
  assignedAt: timestamp('assigned_at'),
  handlingStartedAt: timestamp('handling_started_at'),
  handlingCompletedAt: timestamp('handling_completed_at'),

  // Pause/Hold Logic (Synced with Mobile)
  pausedAt: timestamp('paused_at'),
  totalPausedDurationSeconds: integer('total_paused_duration_seconds').default(0),
  holdReason: text('hold_reason'),
  holdPhoto: text('hold_photo'),

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
  reportId: integer('report_id').references(() => reports.id), // Nullable for system/user logs
  fromStatus: text('from_status'),
  toStatus: text('to_status'),
  action: text('action').notNull(), // created, verified, handling, completed, rejected, approved, recalled, overrideRejection, approveRejection, archived, paused, resumed

  // Actor details (Denormalized for timeline performance, as expected by mobile app)
  actorId: text('actor_id').notNull(),
  actorName: text('actor_name').notNull(),
  actorRole: text('actor_role').notNull(),

  reason: text('reason'), // Mobile app uses 'reason' instead of 'notes'
  mediaUrls: jsonb('media_urls').default([]),
  timestamp: timestamp('timestamp').defaultNow(),
});

// Notifications table
export const notifications = pgTable('notifications', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').references(() => users.id),
  staffId: integer('staff_id').references(() => staff.id),
  reportId: integer('report_id').references(() => reports.id),
  title: text('title').notNull(),
  message: text('message').notNull(),
  type: text('type').notNull().default('info'), // 'info', 'success', 'warning', 'emergency'
  isRead: boolean('is_read').default(false),
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
export type Notification = typeof notifications.$inferSelect;
export type NewNotification = typeof notifications.$inferInsert;
export type Building = typeof buildings.$inferSelect;
export type NewBuilding = typeof buildings.$inferInsert;

