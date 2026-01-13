import { Elysia, t } from 'elysia';
import { randomUUID } from 'crypto';
import { mkdir, writeFile } from 'fs/promises';
import { join } from 'path';

// Ensure uploads directory exists
const UPLOAD_DIR = './uploads';

export const uploadController = new Elysia({ prefix: '/upload' })
  // Upload Image
  .post('/', async ({ body }) => {
    try {
      // Ensure directory exists
      await mkdir(UPLOAD_DIR, { recursive: true });

      // Generate unique filename
      const ext = body.file.name.split('.').pop() || 'jpg';
      const filename = `${randomUUID()}.${ext}`;
      const filepath = join(UPLOAD_DIR, filename);

      // Write file
      const buffer = await body.file.arrayBuffer();
      await writeFile(filepath, Buffer.from(buffer));

      // Return URL (in production, would be CDN URL)
      const url = `/uploads/${filename}`;

      return {
        status: 'success',
        message: 'File uploaded successfully',
        data: {
          filename,
          url,
        },
      };
    } catch (error) {
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
