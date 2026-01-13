import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, categories } from '../../db/schema';
import { eq, desc } from 'drizzle-orm';

export const reportController = new Elysia({ prefix: '/reports' })
  // Get All Public Reports (with optional filters)
  .get('/', async ({ query }) => {
    const { category, building, status } = query;
    
    let result = await db
      .select()
      .from(reports)
      .orderBy(desc(reports.createdAt))
      .limit(50);

    // Apply filters (basic implementation)
    if (category) {
      result = result.filter(r => r.building?.includes(category as string));
    }
    
    return {
      status: 'success',
      data: result,
    };
  }, {
    query: t.Object({
      category: t.Optional(t.String()),
      building: t.Optional(t.String()),
      status: t.Optional(t.String()),
    }),
  })
  
  // Get User's Own Reports
  .get('/my/:userId', async ({ params }) => {
    const result = await db
      .select()
      .from(reports)
      .where(eq(reports.userId, parseInt(params.userId)))
      .orderBy(desc(reports.createdAt));

    return {
      status: 'success',
      data: result,
    };
  })

  // Get Single Report by ID
  .get('/:id', async ({ params }) => {
    const result = await db
      .select()
      .from(reports)
      .where(eq(reports.id, parseInt(params.id)))
      .limit(1);

    if (result.length === 0) {
      return { status: 'error', message: 'Report not found' };
    }

    return {
      status: 'success',
      data: result[0],
    };
  })

  // Create New Report
  .post('/', async ({ body }) => {
    const newReport = await db.insert(reports).values({
      userId: body.userId,
      categoryId: body.categoryId,
      title: body.title,
      description: body.description,
      building: body.building,
      latitude: body.latitude,
      longitude: body.longitude,
      imageUrl: body.imageUrl,
      isEmergency: body.isEmergency,
      notes: body.notes,
      status: 'pending',
    }).returning();

    return {
      status: 'created',
      message: 'Laporan berhasil dikirim!',
      data: newReport[0],
    };
  }, {
    body: t.Object({
      userId: t.Optional(t.Number()),
      categoryId: t.Optional(t.Number()),
      title: t.String(),
      description: t.String(),
      building: t.String(),
      latitude: t.Optional(t.Number()),
      longitude: t.Optional(t.Number()),
      imageUrl: t.Optional(t.String()),
      isEmergency: t.Optional(t.Boolean()),
      notes: t.Optional(t.String()),
    }),
  })

  // Update Report Status (for Teknisi)
  .patch('/:id/status', async ({ params, body }) => {
    const updated = await db
      .update(reports)
      .set({ status: body.status, updatedAt: new Date() })
      .where(eq(reports.id, parseInt(params.id)))
      .returning();

    return {
      status: 'success',
      message: `Status updated to ${body.status}`,
      data: updated[0],
    };
  }, {
    body: t.Object({
      status: t.String(), // pending, verifikasi, penanganan, selesai
    }),
  })

  // Get Categories
  .get('/categories', async () => {
    const result = await db.select().from(categories);
    return {
      status: 'success',
      data: result,
    };
  });
