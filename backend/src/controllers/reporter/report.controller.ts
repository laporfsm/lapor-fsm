import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, categories, reportLogs, users, staff } from '../../db/schema';
import { eq, desc, and, or, sql, gte, lte, ilike } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';

export const reportController = new Elysia({ prefix: '/reports' })
  // Get All Reports (Public Feed with database filtering)
  .get('/', async ({ query }) => {
    const {
      categoryId,
      category,
      building,
      status,
      search,
      isEmergency,
      period,
      startDate,
      endDate,
      limit = '50',
      offset = '0'
    } = query;
    const limitNum = parseInt(limit);
    const offsetNum = parseInt(offset);

    let conditions = [];

    if (categoryId) conditions.push(eq(reports.categoryId, parseInt(categoryId)));
    if (category) conditions.push(eq(categories.name, category));
    if (building) conditions.push(eq(reports.building, building));

    // Status Filter (Support comma-separated or single)
    if (status) {
      const statuses = status.split(',');
      if (statuses.length > 1) {
        conditions.push(or(...statuses.map(s => eq(reports.status, s))));
      } else {
        conditions.push(eq(reports.status, status));
      }
    }

    // Search filter - more robust using built-in ilike helper if available or better sql template
    if (search && search.trim().length > 0) {
      const searchTerms = search.trim().split(/\s+/);
      searchTerms.forEach(term => {
        const pattern = `%${term}%`;
        conditions.push(or(
          ilike(reports.title, pattern),
          ilike(reports.description, pattern)
        ));
      });
    }

    // Emergency filter
    if (isEmergency === 'true') {
      conditions.push(eq(reports.isEmergency, true));
    }

    // Date/Period Filter
    if (startDate && endDate) {
      conditions.push(and(
        gte(reports.createdAt, new Date(startDate)),
        lte(reports.createdAt, new Date(endDate))
      ));
    } else if (period) {
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      if (period === 'today') {
        conditions.push(gte(reports.createdAt, today));
      } else if (period === 'week') {
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        conditions.push(gte(reports.createdAt, weekAgo));
      } else if (period === 'month') {
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        conditions.push(gte(reports.createdAt, monthStart));
      }
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const reporterStaff = alias(staff, 'reporter_staff');
    const handlerStaff = alias(staff, 'handler_staff');

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
        // Coalesce reporter info from either users or staff
        reporterName: sql<string>`COALESCE(${users.name}, ${reporterStaff.name})`,
        reporterEmail: sql<string>`COALESCE(${users.email}, ${reporterStaff.email})`,
        reporterPhone: sql<string>`COALESCE(${users.phone}, ${reporterStaff.phone})`,
        categoryName: categories.name,
        handlerName: handlerStaff.name,
        approvedBy: reports.approvedBy,
        verifiedBy: reports.verifiedBy,
        supervisorName: sql<string>`(SELECT name FROM staff WHERE id = ${reports.approvedBy})`,
        pausedAt: reports.pausedAt,
        totalPausedDurationSeconds: reports.totalPausedDurationSeconds,
        holdReason: reports.holdReason,
        holdPhoto: reports.holdPhoto,
        assignedTo: reports.assignedTo,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(reporterStaff, eq(reports.staffId, reporterStaff.id))
      .leftJoin(categories, eq(reports.categoryId, categories.id))
      .leftJoin(handlerStaff, eq(reports.assignedTo, handlerStaff.id))
      .where(whereClause)
      .orderBy(desc(reports.createdAt))
      .limit(limitNum)
      .offset(offsetNum);

    return {
      status: 'success',
      data: result.map(r => mapToMobileReport(r)),
    };
  }, {
    query: t.Object({
      categoryId: t.Optional(t.String()),
      category: t.Optional(t.String()),
      building: t.Optional(t.String()),
      status: t.Optional(t.String()),
      search: t.Optional(t.String()),
      isEmergency: t.Optional(t.String()),
      period: t.Optional(t.String()),
      startDate: t.Optional(t.String()),
      endDate: t.Optional(t.String()),
      limit: t.Optional(t.String()),
      offset: t.Optional(t.String()),
    }),
  })

  // Get User's Own Reports (History)
  .get('/my/:id', async ({ params, query }) => {
    const id = parseInt(params.id);
    const { role = 'user' } = query;
    console.log(`Fetching history for ID: ${id}, Role: ${role}`);

    let condition;
    if (role === 'user' || role === 'pelapor') {
      condition = eq(reports.userId, id);
    } else {
      // For staff (teknisi, supervisor, pj_gedung), filter by reports.staffId
      condition = eq(reports.staffId, id);
    }

    const reporterStaff = alias(staff, 'reporter_staff');
    const handlerStaff = alias(staff, 'handler_staff');

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
        reporterName: sql<string>`COALESCE(${users.name}, ${reporterStaff.name})`,
        reporterEmail: sql<string>`COALESCE(${users.email}, ${reporterStaff.email})`,
        reporterPhone: sql<string>`COALESCE(${users.phone}, ${reporterStaff.phone})`,
        categoryName: categories.name,
        handlerName: handlerStaff.name,
        approvedBy: reports.approvedBy,
        verifiedBy: reports.verifiedBy,
        supervisorName: sql<string>`(SELECT name FROM staff WHERE id = ${reports.approvedBy})`,
        pausedAt: reports.pausedAt,
        totalPausedDurationSeconds: reports.totalPausedDurationSeconds,
        holdReason: reports.holdReason,
        holdPhoto: reports.holdPhoto,
        assignedTo: reports.assignedTo,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(reporterStaff, eq(reports.staffId, reporterStaff.id))
      .leftJoin(categories, eq(reports.categoryId, categories.id))
      .leftJoin(handlerStaff, eq(reports.assignedTo, handlerStaff.id))
      .where(condition)
      .orderBy(desc(reports.createdAt));

    console.log(`Found ${result.length} reports for history.`);

    return {
      status: 'success',
      data: result.map(r => mapToMobileReport(r)),
    };
  }, {
    query: t.Object({
      role: t.Optional(t.String()),
    })
  })

  // Get Single Report by ID
  .get('/:id', async ({ params }) => {
    const reportId = parseInt(params.id);
    const reporterStaff = alias(staff, 'reporter_staff');
    const handlerStaff = alias(staff, 'handler_staff');

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
        pausedAt: reports.pausedAt,
        totalPausedDurationSeconds: reports.totalPausedDurationSeconds,
        holdReason: reports.holdReason,
        holdPhoto: reports.holdPhoto,
        reporterName: sql<string>`COALESCE(${users.name}, ${reporterStaff.name})`,
        reporterEmail: sql<string>`COALESCE(${users.email}, ${reporterStaff.email})`,
        reporterPhone: sql<string>`COALESCE(${users.phone}, ${reporterStaff.phone})`,
        categoryName: categories.name,
        handlerName: handlerStaff.name,
        supervisorName: sql<string>`(SELECT name FROM staff WHERE id = ${reports.approvedBy})`,
        assignedTo: reports.assignedTo,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(reporterStaff, eq(reports.staffId, reporterStaff.id))
      .leftJoin(categories, eq(reports.categoryId, categories.id))
      .leftJoin(handlerStaff, eq(reports.assignedTo, handlerStaff.id))
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

    // --- NOTIFICATION TRIGGER ---
    try {
      if (body.isEmergency) {
        await NotificationService.broadcastEmergency(
          'LAPORAN DARURAT!',
          `Ada laporan darurat di ${body.building}: ${body.title}`
        );
      } else {
        // Notify Supervisors & PJ Gedung (General Info)
        await NotificationService.notifyRole('supervisor', 'Laporan Baru', `Laporan baru di ${body.building}: ${body.title}`);
        // TODO: Ideally filter PJ by building
        await NotificationService.notifyRole('pj_gedung', 'Laporan Baru', `Laporan baru di ${body.building}: ${body.title}`);
      }
    } catch (e) {
      console.error('Notification Trigger Failed:', e);
    }
    // ----------------------------

    // Fetch the full report with joins for the response
    const reporterStaff = alias(staff, 'reporter_staff');
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
        staffId: reports.staffId,
        reporterName: sql<string>`COALESCE(${users.name}, ${reporterStaff.name})`,
        categoryName: categories.name,
      })
      .from(reports)
      .leftJoin(users, eq(reports.userId, users.id))
      .leftJoin(reporterStaff, eq(reports.staffId, reporterStaff.id))
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
