import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte } from 'drizzle-orm';

export const supervisorController = new Elysia({ prefix: '/supervisor' })
    // Dashboard statistics
    .get('/dashboard/:staffId', async ({ params }) => {
        const now = new Date();
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

        // Count reports by status
        const statusCounts = await db
            .select({
                status: reports.status,
                count: count(),
            })
            .from(reports)
            .groupBy(reports.status);

        // Count today's reports
        const todayCount = await db
            .select({ count: count() })
            .from(reports)
            .where(gte(reports.createdAt, startOfDay));

        // Recent completed reports (for review)
        const pendingReview = await db
            .select({
                id: reports.id,
                title: reports.title,
                status: reports.status,
                handlingCompletedAt: reports.handlingCompletedAt,
                handlerMediaUrls: reports.handlerMediaUrls,
            })
            .from(reports)
            .where(eq(reports.status, 'selesai'))
            .orderBy(desc(reports.handlingCompletedAt))
            .limit(5);

        // Active technicians
        const activeTechnicians = await db
            .select({
                id: staff.id,
                name: staff.name,
            })
            .from(staff)
            .where(and(eq(staff.role, 'teknisi'), eq(staff.isActive, true)));

        return {
            status: 'success',
            data: {
                statusCounts: statusCounts.reduce((acc, curr) => {
                    acc[curr.status || 'unknown'] = curr.count;
                    return acc;
                }, {} as Record<string, number>),
                todayReports: todayCount[0]?.count || 0,
                pendingReview,
                activeTechnicians,
            },
        };
    })

    // Get all reports with filters
    .get('/reports', async ({ query }) => {
        const { status, building, startDate, endDate, page = '1', limit = '20' } = query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        let conditions = [];

        if (status && status !== 'all') {
            conditions.push(eq(reports.status, status));
        }
        if (building) {
            conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
        }
        if (startDate) {
            conditions.push(gte(reports.createdAt, new Date(startDate)));
        }
        if (endDate) {
            conditions.push(lte(reports.createdAt, new Date(endDate)));
        }

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const reportsList = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                building: reports.building,
                locationDetail: reports.locationDetail,
                mediaUrls: reports.mediaUrls,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                assignedAt: reports.assignedAt,
                handlingStartedAt: reports.handlingStartedAt,
                handlingCompletedAt: reports.handlingCompletedAt,
                handlerNotes: reports.handlerNotes,
                handlerMediaUrls: reports.handlerMediaUrls,
                // Reporter info
                reporterName: users.name,
                // Category info
                categoryName: categories.name,
                // Handler info
                handlerName: staff.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .where(whereClause)
            .orderBy(desc(reports.createdAt))
            .limit(limitNum)
            .offset(offset);

        const totalCountResult = await db
            .select({ count: count() })
            .from(reports)
            .where(whereClause);

        return {
            status: 'success',
            data: reportsList,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total: totalCountResult[0]?.count || 0,
                totalPages: Math.ceil((totalCountResult[0]?.count || 0) / limitNum),
            },
        };
    })

    // Verify report (by PJ Gedung or Supervisor)
    .post('/reports/:id/verify', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                status: 'terverifikasi',
                verifiedBy: staffId,
                verifiedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: staffId,
            action: 'verified',
            fromStatus: 'pending',
            toStatus: 'terverifikasi',
            notes: body.notes || 'Laporan telah diverifikasi',
        });

        return { status: 'success', data: updated[0] };
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    })

    // Assign technician
    .post('/reports/:id/assign', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        
        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan',
                assignedTo: body.technicianId,
                assignedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: body.supervisorId,
            action: 'assigned',
            fromStatus: updated[0].status || 'terverifikasi',
            toStatus: 'penanganan',
            notes: `Laporan ditugaskan ke teknisi`,
        });

        return { status: 'success', data: updated[0] };
    }, {
        body: t.Object({
            supervisorId: t.Number(),
            technicianId: t.Number(),
        })
    })

    // Review and approve
    .post('/reports/:id/approve', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                status: 'approved',
                approvedBy: staffId,
                approvedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: staffId,
            action: 'approved',
            fromStatus: 'selesai',
            toStatus: 'approved',
            notes: body.notes || 'Penanganan disetujui',
        });

        return { status: 'success', data: updated[0] };
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    })

    // Reject / Recall
    .post('/reports/:id/reject', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan', // Send back to handling
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: staffId,
            action: 'rejected',
            fromStatus: 'selesai',
            toStatus: 'penanganan',
            notes: body.reason,
        });

        return { status: 'success', data: updated[0] };
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    });
