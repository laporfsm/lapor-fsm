ALTER TABLE "staff"
ADD COLUMN IF NOT EXISTS "password_reset_token" text;

ALTER TABLE "staff"
ADD COLUMN IF NOT EXISTS "password_reset_expires_at" timestamp;
