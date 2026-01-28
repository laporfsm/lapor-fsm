import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, categories, reportLogs, users, staff } from '../../db/schema';
import { eq, desc, and, or, sql } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';

export const reportController = new Elysia({ prefix: '/reports' })
  // Get All Reports (with optional filters)
  .get('/', async ({ query }) => {
    const { categoryId, category, building, status } = query;
    
    const result = await db
      .select({
        id: reports.id,
        title: reports.title,
        description: reports.description,
        building: reports.building,
        locationDetail: reports.locationDetail,
        latitude: reports.latitude,
        longitude: reports.longitude,
        mediaUrls: reports.mediaUrls,
        isEmergency: reports.isEmergency,
        status: reports.status,
        createdAt: reports.createdAt,
        userId: reports.userId,
        staffId: reports.staffId,
        categoryId: reports.categoryId,
        // Detailed Info
        reporterName: users.name,
        reporterEmail: users.email,
        reporterPhone: users.phone,
        categoryName: categories.name,
        handlerName: staff.name,
        supervisorName: sql<string>`(SELECT name FROM staff WHERE id = ${reports.approvedBy})`,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(categories, eq(reports.categoryId, categories.id))
      .leftJoin(staff, eq(reports.assignedTo, staff.id))
      .orderBy(desc(reports.createdAt))
      .limit(100);

    let filtered = result;
    if (categoryId) filtered = filtered.filter(r => r.categoryId === parseInt(categoryId as string));
    if (category) filtered = filtered.filter(r => r.categoryName === category);
    if (building) filtered = filtered.filter(r => r.building === building);
    if (status) filtered = filtered.filter(r => r.status === status);
    
    return {
      status: 'success',
      data: filtered.map(r => mapToMobileReport(r)),
    };
  }, {
    query: t.Object({
      categoryId: t.Optional(t.String()),
      category: t.Optional(t.String()),
      building: t.Optional(t.String()),
      status: t.Optional(t.String()),
    }),
  })
  
  // Get User's Own Reports
  .get('/my/:userId', async ({ params }) => {
    const result = await db
      .select({
        id: reports.id,
        title: reports.title,
        description: reports.description,
        building: reports.building,
        locationDetail: reports.locationDetail,
        latitude: reports.latitude,
        longitude: reports.longitude,
        mediaUrls: reports.mediaUrls,
        isEmergency: reports.isEmergency,
        status: reports.status,
        createdAt: reports.createdAt,
        userId: reports.userId,
        // Detailed Info
        reporterName: users.name,
        categoryName: categories.name,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(categories, eq(reports.categoryId, categories.id))
      .where(eq(reports.userId, parseInt(params.userId)))
      .orderBy(desc(reports.createdAt));

    return {
      status: 'success',
      data: result.map(r => mapToMobileReport(r)),
    };
  })

  // Get Single Report by ID
  .get('/:id', async ({ params }) => {
    const reportId = parseInt(params.id);
    const result = await db
      .select({
        id: reports.id,
        title: reports.title,
        description: reports.description,
        building: reports.building,
        locationDetail: reports.locationDetail,
        latitude: reports.latitude,
        longitude: reports.longitude,
        mediaUrls: reports.mediaUrls,
        isEmergency: reports.isEmergency,
        status: reports.status,
        createdAt: reports.createdAt,
        userId: reports.userId,
        pausedAt: reports.pausedAt,
        totalPausedDurationSeconds: reports.totalPausedDurationSeconds,
        holdReason: reports.holdReason,
        holdPhoto: reports.holdPhoto,
        // Detailed Info
        reporterName: users.name,
        reporterEmail: users.email,
        reporterPhone: users.phone,
        categoryName: categories.name,
        handlerName: staff.name,
        supervisorName: sql<string>`(SELECT name FROM staff WHERE id = ${reports.approvedBy})`,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(categories, eq(reports.categoryId, categories.id))
      .leftJoin(staff, eq(reports.assignedTo, staff.id))
      .where(eq(reports.id, reportId))
      .limit(1);

    if (result.length === 0) {
      return { status: 'error', message: 'Report not found' };
    }

    const logsList = await db
      .select()
      .from(reportLogs)
      .where(eq(reportLogs.reportId, reportId))
      .orderBy(desc(reportLogs.timestamp));

    return {
      status: 'success',
      data: mapToMobileReport(result[0], logsList),
    };
  })

  // Create New Report
  .post('/', async ({ body }) => {
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

    // Get actor info for logs
    let actorName = "Anonymous";
    let actorRole = "user";
    if (body.userId) {
      const u = await db.select().from(users).where(eq(users.id, body.userId)).limit(1);
      if (u.length > 0) { actorName = u[0].name; }
    } else if (body.staffId) {
      const s = await db.select().from(staff).where(eq(staff.id, body.staffId)).limit(1);
      if (s.length > 0) { actorName = s[0].name; actorRole = s[0].role; }
    }

    // Log the creation
    await db.insert(reportLogs).values({
      reportId: newReport[0].id,
      actorId: (body.userId || body.staffId || 0).toString(),
      actorName: actorName,
      actorRole: actorRole,
      action: 'created',
      toStatus: 'pending',
      reason: body.notes || 'Laporan baru dibuat',
    });

    // Fetch the full report with joins for the response
    const fullReport = await db
        .select({
            id: reports.id,
            title: reports.title,
            description: reports.description,
            building: reports.building,
            locationDetail: reports.locationDetail,
            latitude: reports.latitude,
            longitude: reports.longitude,
            mediaUrls: reports.mediaUrls,
            isEmergency: reports.isEmergency,
            status: reports.status,
            createdAt: reports.createdAt,
            userId: reports.userId,
            reporterName: users.name,
            categoryName: categories.name,
        })
        .from(reports)
        .leftJoin(users, eq(reports.userId, users.id))
        .leftJoin(categories, eq(reports.categoryId, categories.id))
        .where(eq(reports.id, newReport[0].id))
        .limit(1);

    return {
      status: 'created',
      message: 'Laporan berhasil dikirim!',
      data: mapToMobileReport(fullReport[0]),
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
      imageUrl: t.Optional(t.String()),
      notes: t.Optional(t.String()),
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
