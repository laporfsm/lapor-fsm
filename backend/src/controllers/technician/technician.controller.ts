import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, isNull, gte, count } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';

import { getStartOfWeek, getStartOfMonth, getStartOfDay } from '../../utils/date.utils';

export const technicianController = new Elysia({ prefix: '/technician' })
    // Dashboard statistics for technician
    .get('/dashboard/:staffId', async ({ params }) => {
        const staffId = parseInt(params.staffId);
        const startOfDay = getStartOfDay();
        const startOfWeek = getStartOfWeek();
        const startOfMonth = getStartOfMonth();

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

        // Waiting for technician to accept (Original Logic: Only Assigned)
        // New Logic: Pool (Unassigned) + Personal (Assigned to me) with status 'diproses'
        const diprosesCount = await db
            .select({ count: count() })
            .from(reports)
            .where(
                and(
                    eq(reports.status, 'diproses'),
                    or(
                        eq(reports.assignedTo, staffId),
                        isNull(reports.assignedTo) // Include pool
                    )
                )
            );

        // Time based counts - using handlingStartedAt for when technician started working
        const todayReports = await db.select({ count: count() }).from(reports).where(and(eq(reports.assignedTo, staffId), gte(reports.handlingStartedAt, startOfDay)));
        const weekReports = await db.select({ count: count() }).from(reports).where(and(eq(reports.assignedTo, staffId), gte(reports.handlingStartedAt, startOfWeek)));
        const monthReports = await db.select({ count: count() }).from(reports).where(and(eq(reports.assignedTo, staffId), gte(reports.handlingStartedAt, startOfMonth)));

        // Emergency pending
        const emergencyCount = await db
            .select({ count: count() })
            .from(reports)
            .where(and(eq(reports.isEmergency, true), eq(reports.status, 'diproses')));

        // Recalled reports (supervisor asked for revision)
        const recalledCount = await db
            .select({ count: count() })
            .from(reports)
            .where(and(eq(reports.assignedTo, staffId), eq(reports.status, 'recalled')));

        return {
            status: 'success',
            data: {
                diproses: Number(diprosesCount[0]?.count || 0),
                penanganan: (Number(countsMap['penanganan'] || 0) + Number(countsMap['onHold'] || 0) + Number(countsMap['recalled'] || 0) + Number(countsMap['selesai'] || 0)),
                approved: Number(countsMap['approved'] || 0), // Explicitly return approved count
                onHold: Number(countsMap['onHold'] || 0),
                selesai: Number(countsMap['selesai'] || 0),
                recalled: Number(countsMap['recalled'] || 0),
                todayReports: Number(todayReports[0]?.count || 0),
                weekReports: Number(weekReports[0]?.count || 0),
                monthReports: Number(monthReports[0]?.count || 0),
                emergency: Number(emergencyCount[0]?.count || 0),
            },
        };
    })

    // Get reports for technician with query parameters (consistent with other roles)
    .get('/reports', async ({ query }) => {
        const { status, isEmergency, page = '1', limit = '50' } = query;
        const pageNum = isNaN(parseInt(page)) ? 1 : parseInt(page);
        const limitNum = isNaN(parseInt(limit)) ? 50 : parseInt(limit);
        const offsetNum = (pageNum - 1) * limitNum;

        let conditions = [];
        conditions.push(isNull(reports.parentId));

        // Filter by status
        if (status && status !== 'all') {
            const statusList = status.split(',').map(s => s.trim());
            if (statusList.length > 1) {
                conditions.push(or(...statusList.map(s => eq(reports.status, s))));
            } else {
                conditions.push(eq(reports.status, statusList[0]));
            }
        }

        // For 'diproses' status, show all (any technician can pick up)
        // For other statuses, only show what's assigned to them (handled in frontend)

        if (isEmergency === 'true') {
            conditions.push(eq(reports.isEmergency, true));
        } else if (isEmergency === 'false') {
            conditions.push(eq(reports.isEmergency, false));
        }

        // Filter by assignedTo
        if (query.assignedTo && !isNaN(parseInt(query.assignedTo))) {
            conditions.push(eq(reports.assignedTo, parseInt(query.assignedTo)));
        }

        // Filter by period (based on handlingStartedAt)
        if (query.period) {
            const now = new Date();
            if (query.period === 'today') {
                conditions.push(gte(reports.handlingStartedAt, getStartOfDay()));
            } else if (query.period === 'week') {
                conditions.push(gte(reports.handlingStartedAt, getStartOfWeek()));
            } else if (query.period === 'month') {
                conditions.push(gte(reports.handlingStartedAt, getStartOfMonth()));
            }
        }

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        // Get total count for pagination
        const totalResult = await db
            .select({ count: count() })
            .from(reports)
            .where(whereClause);

        const totalCount = totalResult[0]?.count || 0;

        const reporterStaff = alias(staff, 'reporter_staff');

        const reportsList = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                location: reports.location,
                locationDetail: reports.locationDetail,
                latitude: reports.latitude,
                longitude: reports.longitude,
                mediaUrls: reports.mediaUrls,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                userId: reports.userId,
                staffId: reports.staffId,
                assignedTo: reports.assignedTo,
                // Detailed Info logic similar to report controller
                reporterName: sql<string>`COALESCE(${users.name}, ${reporterStaff.name})`,
                reporterPhone: sql<string>`COALESCE(${users.phone}, ${reporterStaff.phone})`,
                categoryName: categories.name,
                handlerName: staff.name,
                approvedBy: reports.approvedBy,
                verifiedBy: reports.verifiedBy,
                supervisorName: sql<string>`(SELECT name FROM staff WHERE id = COALESCE(${reports.approvedBy}, ${reports.verifiedBy}))`,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(reporterStaff, eq(reports.staffId, reporterStaff.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .where(whereClause)
            .orderBy(desc(reports.isEmergency), desc(reports.createdAt))
            .limit(limitNum)
            .offset(offsetNum);

        return {
            status: 'success',
            data: reportsList.map(r => mapToMobileReport(r)),
            total: totalCount,
        };
    })

    // Get all reports for technician (new tasks and active tasks) - legacy endpoint with staffId
    .get('/reports/:staffId', async ({ params }) => {
        const staffId = parseInt(params.staffId);

        const reportsList = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                location: reports.location,
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
                handlerName: staff.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .where(
                and(
                    isNull(reports.parentId),
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
            )
            .orderBy(desc(reports.isEmergency), desc(reports.createdAt));

        return {
            status: 'success',
            data: reportsList.map(r => mapToMobileReport(r)),
        };
    })

    // Accept task (Start Penanganan) - from diproses or recalled
    .post('/reports/:id/accept', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);
        if (foundStaff.length === 0) return { status: 'error', message: 'Staff tidak ditemukan' };

        // Get current report to check status
        const currentReport = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (currentReport.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        const fromStatus = currentReport[0].status || 'diproses';

        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan',
                assignedTo: staffId,
                handlingStartedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Gagal mengupdate laporan' };

        const actionReason = fromStatus === 'recalled'
            ? 'Melanjutkan penanganan setelah recall'
            : 'Mulai penanganan laporan';

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0].name,
            actorRole: foundStaff[0].role,
            action: 'handling',
            fromStatus: fromStatus,
            toStatus: 'penanganan',
            reason: actionReason,
        });

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Laporan Sedang Dikerjakan', `Teknisi ${foundStaff[0].name} sedang mengerjakan laporan Anda.`, 'info', reportId);
        }

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

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Laporan Ditunda', `Pengerjaan laporan "${updated[0].title}" ditunda sementara: ${body.reason}`, 'warning', reportId);
        }

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

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Pengerjaan Dilanjutkan', `Teknisi melanjutkan pengerjaan laporan Anda: ${updated[0].title}`, 'info', reportId);
        }

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

        // Notify Supervisor
        await NotificationService.notifyRole('supervisor', 'Pengerjaan Selesai', `Teknisi ${foundStaff[0]?.name || ''} telah menyelesaikan laporan: ${updated[0].title}`, 'info', reportId);

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Laporan Menunggu Persetujuan', `Laporan Anda telah diselesaikan oleh teknisi dan sedang menunggu persetujuan supervisor.`, 'info', reportId);
        }

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
                location: reports.location,
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
                approvedBy: reports.approvedBy,
                verifiedBy: reports.verifiedBy,
                supervisorName: sql<string>`(SELECT name FROM staff WHERE id = COALESCE(${reports.approvedBy}, ${reports.verifiedBy}))`,
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
