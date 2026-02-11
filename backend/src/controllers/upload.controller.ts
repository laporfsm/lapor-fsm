import { Elysia, t } from 'elysia';
import { randomUUID } from 'crypto';
import { mkdir, writeFile, unlink } from 'fs/promises';
import { join } from 'path';
import admin from 'firebase-admin';

// Ensure uploads directory exists (for temporary storage before cloud upload)
const UPLOAD_DIR = './uploads';
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';

export const uploadController = new Elysia({ prefix: '/upload' })
  // Upload Image
  .post('/', async ({ body }) => {
    try {
      // 1. Prepare local temp storage
      await mkdir(UPLOAD_DIR, { recursive: true });

      // Generate unique filename
      const ext = body.file.name.split('.').pop() || 'jpg';
      const filename = `${randomUUID()}.${ext}`;
      const filepath = join(UPLOAD_DIR, filename);

      // 2. Write file validation to local temp
      const buffer = await body.file.arrayBuffer();
      await writeFile(filepath, Buffer.from(buffer));

      let url = `${API_BASE_URL}/uploads/${filename}`;

      // 3. Try Upload to Cloud Storage (Firebase) if Initialized
      if (admin.apps.length > 0) {
        try {
          const bucket = admin.storage().bucket();
          const [fileApi] = await bucket.upload(filepath, {
            destination: `uploads/${filename}`,
            public: true, // Make file public readable
            metadata: {
              contentType: body.file.type,
            }
          });

          // Get public URL
          // Format: https://storage.googleapis.com/BUCKET_NAME/uploads/FILENAME
          url = fileApi.publicUrl();
          console.log(`☁️ Uploaded to Firebase: ${url}`);

          // Remove local temp file
          await unlink(filepath).catch(() => { });
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
        },
      };

    } catch (error) {
      console.error('Upload Error:', error);
      return {
        status: 'error',
        message: 'Failed to upload file',
      };
    }
  }, {
    body: t.Object({
      file: t.File(),
    }),
  });
