import { Elysia, t } from 'elysia';
import { randomUUID } from 'crypto';
import { mkdir, writeFile, unlink } from 'fs/promises';
import { join } from 'path';
import admin from 'firebase-admin';

// Ensure uploads directory exists (for temporary storage before cloud upload)
const UPLOAD_DIR = './uploads';
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';

// Allowed file types and max size (10MB)
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

export const uploadController = new Elysia({ prefix: '/upload' })
  // Upload Image
  .post('/', async ({ body, set }) => {
    try {
      const file = body.file;

      // 1. Validate file type
      if (!ALLOWED_MIME_TYPES.includes(file.type)) {
        set.status = 400;
        return {
          status: 'error',
          message: 'Invalid file type. Only JPEG, PNG, WebP, and GIF images are allowed.',
        };
      }

      // 2. Validate file size
      const buffer = await file.arrayBuffer();
      if (buffer.byteLength > MAX_FILE_SIZE) {
        set.status = 400;
        return {
          status: 'error',
          message: `File too large. Maximum size is ${MAX_FILE_SIZE / (1024 * 1024)}MB.`,
        };
      }

      // 3. Prepare local temp storage
      await mkdir(UPLOAD_DIR, { recursive: true });

      // Generate unique filename with proper extension
      const ext = file.name.split('.').pop()?.toLowerCase() || 'jpg';
      const sanitizedExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext) ? ext : 'jpg';
      const filename = `${randomUUID()}.${sanitizedExt}`;
      const filepath = join(UPLOAD_DIR, filename);

      // 4. Write file to local temp
      await writeFile(filepath, Buffer.from(buffer));

      let url = `${API_BASE_URL}/uploads/${filename}`;

      // 5. Try Upload to Cloud Storage (Firebase) if Initialized
      if (admin.apps.length > 0) {
        try {
          const bucket = admin.storage().bucket();
          const [fileApi] = await bucket.upload(filepath, {
            destination: `uploads/${filename}`,
            public: true, // Make file public readable
            metadata: {
              contentType: file.type,
              cacheControl: 'public, max-age=31536000', // Cache for 1 year
            }
          });

          // Get public URL
          // Format: https://storage.googleapis.com/BUCKET_NAME/uploads/FILENAME
          url = fileApi.publicUrl();
          console.log(`☁️ Uploaded to Firebase: ${url}`);

          // Remove local temp file after successful cloud upload
          await unlink(filepath).catch((err) => {
            console.warn('⚠️ Failed to remove local temp file:', err);
          });
        } catch (storageError) {
          console.error('⚠️ Firebase Storage upload failed, falling back to local:', storageError);
          // Keep local file as fallback
        }
      }

      // Return URL (Cloud or Local)
      return {
        status: 'success',
        message: 'File uploaded successfully',
        data: {
          filename,
          url,
          size: buffer.byteLength,
          type: file.type,
        },
      };

    } catch (error) {
      console.error('Upload Error:', error);
      set.status = 500;
      return {
        status: 'error',
        message: 'Failed to upload file. Please try again.',
      };
    }
  }, {
    body: t.Object({
      file: t.File(),
    }),
  });
