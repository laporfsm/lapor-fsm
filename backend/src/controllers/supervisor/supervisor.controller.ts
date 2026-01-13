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
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

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

        // Count this week's reports
        const weekCount = await db
            .select({ count: count() })
            .from(reports)
            .where(gte(reports.createdAt, startOfWeek));

        // Count this month's reports
        const monthCount = await db
            .select({ count: count() })
            .from(reports)
            .where(gte(reports.createdAt, startOfMonth));

        // Recent completed reports (for review)
        const pendingReview = await db
            .select({
                id: reports.id,
                title: reports.title,
                status: reports.status,
                completedAt: reports.completedAt,
                handlerMediaUrl: reports.handlerMediaUrl,
            })
            .from(reports)
            .where(eq(reports.status, 'selesai'))
            .orderBy(desc(reports.completedAt))
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
                weekReports: weekCount[0]?.count || 0,
                monthReports: monthCount[0]?.count || 0,
                pendingReview,
                activeTechnicians,
            },
        };
    })

    // Get all reports with filters
    .get('/reports', async ({ query }) => {
        const { status, category, building, startDate, endDate, page = '1', limit = '20' } = query;
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
                imageUrl: reports.imageUrl,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                assignedAt: reports.assignedAt,
                handledAt: reports.handledAt,
                completedAt: reports.completedAt,
                handlerNotes: reports.handlerNotes,
                handlerMediaUrl: reports.handlerMediaUrl,
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

        // Total count for pagination
        const totalCount = await db
            .select({ count: count() })
            .from(reports)
            .where(whereClause);

        return {
            status: 'success',
            data: reportsList,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total: totalCount[0]?.count || 0,
                totalPages: Math.ceil((totalCount[0]?.count || 0) / limitNum),
            },
        };
    })

    // Review and approve a completed report
    .post('/reports/:id/approve', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                reviewedBy: staffId,
                reviewedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        await db.insert(reportLogs).values({
            reportId,
            staffId,
            action: 'approved',
            notes: body.notes || 'Penanganan disetujui oleh Supervisor',
        });

        return {
            status: 'success',
            message: 'Laporan disetujui',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
            notes: t.Optional(t.String()),
        }),
    })

    // Recall technician (penanganan ulang)
    .post('/reports/:id/recall', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan_ulang',
                reviewedBy: staffId,
                reviewedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        await db.insert(reportLogs).values({
            reportId,
            staffId,
            action: 'recalled',
            notes: body.reason || 'Teknisi dipanggil kembali untuk penanganan ulang',
        });

        return {
            status: 'success',
            message: 'Teknisi dipanggil kembali',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
            reason: t.String(),
        }),
    })

    // Get archive (completed and reviewed reports)
    .get('/archive', async ({ query }) => {
        const { startDate, endDate, page = '1', limit = '20' } = query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        let conditions = [eq(reports.status, 'selesai')];

        if (startDate) {
            conditions.push(gte(reports.createdAt, new Date(startDate)));
        }
        if (endDate) {
            conditions.push(lte(reports.createdAt, new Date(endDate)));
        }

        const archiveList = await db
            .select({
                id: reports.id,
                title: reports.title,
                building: reports.building,
                isEmergency: reports.isEmergency,
                createdAt: reports.createdAt,
                completedAt: reports.completedAt,
                handlerNotes: reports.handlerNotes,
                categoryName: categories.name,
                reporterName: users.name,
                handlerName: staff.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .where(and(...conditions))
            .orderBy(desc(reports.completedAt))
            .limit(limitNum)
            .offset(offset);

        const totalCount = await db
            .select({ count: count() })
            .from(reports)
            .where(and(...conditions));

        return {
            status: 'success',
            data: archiveList,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total: totalCount[0]?.count || 0,
                totalPages: Math.ceil((totalCount[0]?.count || 0) / limitNum),
            },
        };
    })

    // Get technician performance stats
    .get('/technicians/performance', async () => {
        const technicians = await db
            .select({
                id: staff.id,
                name: staff.name,
            })
            .from(staff)
            .where(eq(staff.role, 'teknisi'));

        // For each technician, get their stats
        const performanceData = await Promise.all(
            technicians.map(async (tech) => {
                const handled = await db
                    .select({ count: count() })
                    .from(reports)
                    .where(eq(reports.assignedTo, tech.id));

                const completed = await db
                    .select({ count: count() })
                    .from(reports)
                    .where(and(
                        eq(reports.assignedTo, tech.id),
                        eq(reports.status, 'selesai')
                    ));

                return {
                    id: tech.id,
                    name: tech.name,
                    totalHandled: handled[0]?.count || 0,
                    totalCompleted: completed[0]?.count || 0,
                };
            })
        );

        return {
            status: 'success',
            data: performanceData,
        };
    })

    // Export data endpoint (returns JSON, frontend will handle PDF/Excel conversion)
    .get('/export', async ({ query }) => {
        const { format, startDate, endDate } = query;

        let conditions = [];
        if (startDate) {
            conditions.push(gte(reports.createdAt, new Date(startDate)));
        }
        if (endDate) {
            conditions.push(lte(reports.createdAt, new Date(endDate)));
        }

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const exportData = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                building: reports.building,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                assignedAt: reports.assignedAt,
                handledAt: reports.handledAt,
                completedAt: reports.completedAt,
                handlerNotes: reports.handlerNotes,
                reporterName: users.name,
                reporterEmail: users.email,
                categoryName: categories.name,
                handlerName: staff.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .where(whereClause)
            .orderBy(desc(reports.createdAt));

        return {
            status: 'success',
            format: format || 'json',
            data: exportData,
        };
    });
