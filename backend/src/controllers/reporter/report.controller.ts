import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, categories, reportLogs } from '../../db/schema';
import { eq, desc, and, or } from 'drizzle-orm';

export const reportController = new Elysia({ prefix: '/reports' })
  // Get All Reports (with optional filters)
  .get('/', async ({ query }) => {
    const { categoryId, category, building, status } = query;
    
    let result = await db
      .select()
      .from(reports)
      .orderBy(desc(reports.createdAt))
      .limit(100);

    // Apply basic JS filtering if query params exist
    if (categoryId) result = result.filter(r => r.categoryId === parseInt(categoryId as string));
    if (category) result = result.filter(r => r.categoryId === parseInt(category as string));
    if (building) result = result.filter(r => r.building === building);
    if (status) result = result.filter(r => r.status === status);
    
    // Add imageUrl for mobile app compatibility
    const compatibleResult = result.map(r => ({
      ...r,
      imageUrl: r.mediaUrls && (r.mediaUrls as string[]).length > 0 ? (r.mediaUrls as string[])[0] : null
    }));

    return {
      status: 'success',
      data: compatibleResult,
    };
  }, {
    query: t.Object({
      categoryId: t.Optional(t.String()),
      category: t.Optional(t.String()), // Mobile app uses this
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

    const compatibleResult = result.map(r => ({
      ...r,
      imageUrl: r.mediaUrls && (r.mediaUrls as string[]).length > 0 ? (r.mediaUrls as string[])[0] : null
    }));

    return {
      status: 'success',
      data: compatibleResult,
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

    const report = result[0];
    const compatibleReport = {
      ...report,
      imageUrl: report.mediaUrls && (report.mediaUrls as string[]).length > 0 ? (report.mediaUrls as string[])[0] : null
    };

    return {
      status: 'success',
      data: compatibleReport,
    };
  })

  // Create New Report
  .post('/', async ({ body }) => {
    // Merge mediaUrls and imageUrl for mobile compatibility
    const finalMediaUrls = [...(body.mediaUrls || [])];
    if (body.imageUrl && !finalMediaUrls.includes(body.imageUrl)) {
      finalMediaUrls.push(body.imageUrl);
    }

    const newReport = await db.insert(reports).values({
      userId: body.userId,
      staffId: body.staffId,
      categoryId: body.categoryId,
      title: body.title,
      description: body.description,
      building: body.building,
      locationDetail: body.locationDetail,
      latitude: body.latitude,
      longitude: body.longitude,
      mediaUrls: finalMediaUrls,
      isEmergency: body.isEmergency || false,
      status: 'pending',
    }).returning();

    // Log the creation
    await db.insert(reportLogs).values({
      reportId: newReport[0].id,
      actorType: body.userId ? 'user' : 'staff',
      actorId: (body.userId || body.staffId) as number,
      action: 'created',
      toStatus: 'pending',
      notes: body.notes || 'Laporan baru dibuat',
    });

    return {
      status: 'created',
      message: 'Laporan berhasil dikirim!',
      data: {
        ...newReport[0],
        imageUrl: finalMediaUrls[0] || null
      },
    };
  }, {
    body: t.Object({
      userId: t.Optional(t.Number()),
      staffId: t.Optional(t.Number()),
      categoryId: t.Optional(t.Number()),
      title: t.String(),
      description: t.String(),
      building: t.String(),
      locationDetail: t.Optional(t.String()),
      latitude: t.Optional(t.Number()),
      longitude: t.Optional(t.Number()),
      mediaUrls: t.Optional(t.Array(t.String())),
      imageUrl: t.Optional(t.String()), // Mobile app compatibility
      notes: t.Optional(t.String()), // Mobile app compatibility
      isEmergency: t.Optional(t.Boolean()),
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
