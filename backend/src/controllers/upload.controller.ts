import { Elysia, t } from 'elysia';
import { randomUUID } from 'crypto';
import { mkdir, writeFile, unlink } from 'fs/promises';
import { join } from 'path';
import { supabase } from '../lib/supabase';

// Ensure uploads directory exists (for temporary storage before cloud upload)
const UPLOAD_DIR = './uploads';
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';

// Allowed file types and max size (50MB for video support)
const ALLOWED_MIME_TYPES = [
  'image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif',
  'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/mpeg'
];
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

export const uploadController = new Elysia({ prefix: '/upload' })
  // Upload Media (Image/Video)
  .post('/', async ({ body, set }) => {
    try {
      const file = body.file;

      // 1. Validate file type
      if (!ALLOWED_MIME_TYPES.includes(file.type)) {
        set.status = 400;
        return {
          status: 'error',
          message: 'Invalid file type. Allowed: JPEG, PNG, WebP, GIF, and MP4/QuickTime videos.',
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
      const originalExt = file.name.split('.').pop()?.toLowerCase() || '';
      const filename = `${randomUUID()}${originalExt ? `.${originalExt}` : ''}`;
      const filepath = join(UPLOAD_DIR, filename);

      // 4. Write file to local temp
      await writeFile(filepath, Buffer.from(buffer));

      let url = `${API_BASE_URL}/uploads/${filename}`;

      // 5. Try Upload to Supabase Storage
      try {
        const bucketName = 'media'; // Make sure this bucket exists in Supabase
        const folder = file.type.startsWith('image/') ? 'images' : 'videos';
        const storagePath = `${folder}/${filename}`;

        const { data, error } = await supabase.storage
          .from(bucketName)
          .upload(storagePath, Buffer.from(buffer), {
            contentType: file.type,
            upsert: false
          });

        if (error) {
          throw error;
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from(bucketName)
          .getPublicUrl(storagePath);

        url = publicUrl;
        console.log(`☁️ Uploaded to Supabase Storage: ${url}`);

        // Remove local temp file after successful cloud upload
        await unlink(filepath).catch((err) => {
          console.warn('⚠️ Failed to remove local temp file:', err);
        });
      } catch (storageError) {
        console.error('⚠️ Supabase Storage upload failed, falling back to local:', storageError);
        // Keep local file as fallback if cloud upload fails
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

