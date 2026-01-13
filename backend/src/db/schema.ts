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
  status: text('status').default('pending'), // pending, verifikasi, penanganan, selesai
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Type exports
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Report = typeof reports.$inferSelect;
export type NewReport = typeof reports.$inferInsert;
export type Category = typeof categories.$inferSelect;
