import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';
import { gte, count } from 'drizzle-orm';

export const technicianController = new Elysia({ prefix: '/technician' })
    // Dashboard statistics for technician
    .get('/dashboard/:staffId', async ({ params }) => {
        const staffId = parseInt(params.staffId);
        const now = new Date();
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

        const statusCounts = await db
            .select({
                status: reports.status,
                count: count(),
            })
            .from(reports)
            .where(eq(reports.assignedTo, staffId))
            .groupBy(reports.status);

        const countsMap = statusCounts.reduce((acc, curr) => {
            acc[curr.status || 'unknown'] = curr.count;
            return acc;
        }, {} as Record<string, number>);

        // Waiting for technician to accept
        const diprosesCount = await db
            .select({ count: count() })
            .from(reports)
            .where(eq(reports.status, 'diproses'));

        // Time based counts
        const todayReports = await db.select({ count: count() }).from(reports).where(and(eq(reports.assignedTo, staffId), gte(reports.createdAt, startOfDay)));
        const weekReports = await db.select({ count: count() }).from(reports).where(and(eq(reports.assignedTo, staffId), gte(reports.createdAt, startOfWeek)));
        const monthReports = await db.select({ count: count() }).from(reports).where(and(eq(reports.assignedTo, staffId), gte(reports.createdAt, startOfMonth)));

        // Emergency pending
        const emergencyCount = await db
            .select({ count: count() })
            .from(reports)
            .where(and(eq(reports.isEmergency, true), eq(reports.status, 'diproses')));

        return {
            status: 'success',
            data: {
                diproses: diprosesCount[0]?.count || 0,
                penanganan: countsMap['penanganan'] || 0,
                onHold: countsMap['onHold'] || 0,
                selesai: (countsMap['selesai'] || 0) + (countsMap['approved'] || 0),
                todayReports: todayReports[0]?.count || 0,
                weekReports: weekReports[0]?.count || 0,
                monthReports: monthReports[0]?.count || 0,
                emergency: emergencyCount[0]?.count || 0,
            },
        };
    })

    // Get all reports for technician (new tasks and active tasks)
    .get('/reports/:staffId', async ({ params }) => {
        const staffId = parseInt(params.staffId);

        const reportsList = await db
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
                reporterPhone: users.phone,
                categoryName: categories.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(
                or(
                    eq(reports.status, 'diproses'), // Waiting for tech to accept
                    and(
                        eq(reports.assignedTo, staffId),
                        or(
                            eq(reports.status, 'penanganan'),
                            eq(reports.status, 'onHold'),
                            eq(reports.status, 'recalled')
                        )
                    )
                )
            )
            .orderBy(desc(reports.isEmergency), desc(reports.createdAt));

        return {
            status: 'success',
            data: reportsList.map(r => mapToMobileReport(r)),
        };
    })

    // Accept task (Start Penanganan)
    .post('/reports/:id/accept', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);
        if (foundStaff.length === 0) return { status: 'error', message: 'Staff tidak ditemukan' };

        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan',
                handlingStartedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0].name,
            actorRole: foundStaff[0].role,
            action: 'handling',
            fromStatus: 'diproses',
            toStatus: 'penanganan',
            reason: 'Mulai penanganan laporan',
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number() }),
    })

    // Pause task (On Hold)
    .post('/reports/:id/pause', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        const updated = await db
            .update(reports)
            .set({
                status: 'onHold',
                pausedAt: new Date(),
                holdReason: body.reason,
                holdPhoto: body.photoUrl,
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "Technician",
            actorRole: foundStaff[0]?.role || "teknisi",
            action: 'paused',
            fromStatus: 'penanganan',
            toStatus: 'onHold',
            reason: body.reason,
            mediaUrls: body.photoUrl ? [body.photoUrl] : [],
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String(), photoUrl: t.Optional(t.String()) }),
    })

    // Resume task
    .post('/reports/:id/resume', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const currentReport = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (currentReport.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        let additionalPausedSeconds = 0;
        if (currentReport[0].pausedAt) {
            additionalPausedSeconds = Math.floor((new Date().getTime() - currentReport[0].pausedAt.getTime()) / 1000);
        }

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan',
                pausedAt: null,
                totalPausedDurationSeconds: (currentReport[0].totalPausedDurationSeconds || 0) + additionalPausedSeconds,
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "Technician",
            actorRole: foundStaff[0]?.role || "teknisi",
            action: 'resumed',
            fromStatus: 'onHold',
            toStatus: 'penanganan',
            reason: 'Pengerjaan dilanjutkan',
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number() }),
    })

    // Complete task
    .post('/reports/:id/complete', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        const updated = await db
            .update(reports)
            .set({
                status: 'selesai',
                handlingCompletedAt: new Date(),
                handlerNotes: body.notes,
                handlerMediaUrls: body.mediaUrls || [],
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "Technician",
            actorRole: foundStaff[0]?.role || "teknisi",
            action: 'completed',
            fromStatus: 'penanganan',
            toStatus: 'selesai',
            reason: body.notes,
            mediaUrls: body.mediaUrls || [],
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({
            staffId: t.Number(),
            notes: t.Optional(t.String()),
            mediaUrls: t.Array(t.String()),
        }),
    })

    // Detail for technician
    .get('/reports/detail/:id', async ({ params }) => {
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
                handlerNotes: reports.handlerNotes,
                handlerMediaUrls: reports.handlerMediaUrls,
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

        if (result.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        const logsList = await db
            .select()
            .from(reportLogs)
            .where(eq(reportLogs.reportId, reportId))
            .orderBy(desc(reportLogs.timestamp));

        return {
            status: 'success',
            data: mapToMobileReport(result[0], logsList),
        };
    });
