import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';

export const pjController = new Elysia({ prefix: '/pj-gedung' })
    // Dashboard statistics for PJ Gedung
    .get('/dashboard', async () => {
        const now = new Date();
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

        const todayReports = await db.select({ count: count() }).from(reports).where(gte(reports.createdAt, startOfDay));
        const weekReports = await db.select({ count: count() }).from(reports).where(gte(reports.createdAt, startOfWeek));
        const monthReports = await db.select({ count: count() }).from(reports).where(gte(reports.createdAt, startOfMonth));

        const statusCounts = await db
            .select({
                status: reports.status,
                count: count(),
            })
            .from(reports)
            .groupBy(reports.status);

        const countsMap = statusCounts.reduce((acc, curr) => {
            acc[curr.status || 'unknown'] = curr.count;
            return acc;
        }, {} as Record<string, number>);

        return {
            status: 'success',
            data: {
                todayReports: todayReports[0]?.count || 0,
                weekReports: weekReports[0]?.count || 0,
                monthReports: monthReports[0]?.count || 0,
                pending: countsMap['pending'] || 0,
                verified: countsMap['terverifikasi'] || 0,
                rejected: countsMap['ditolak'] || 0,
            },
        };
    })

    // Get reports for PJ Gedung (focused on their building if filter provided)
    .get('/reports', async ({ query }) => {
        const { status, building, isEmergency } = query;
        let conditions = [];
        if (status) conditions.push(eq(reports.status, status));
        if (building) conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
        if (isEmergency === 'true') conditions.push(eq(reports.isEmergency, true));

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                building: reports.building,
                locationDetail: reports.locationDetail,
                status: reports.status,
                isEmergency: reports.isEmergency,
                createdAt: reports.createdAt,
                reporterName: users.name,
                categoryName: categories.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(whereClause)
            .orderBy(desc(reports.createdAt));

        return {
            status: 'success',
            data: result.map(r => mapToMobileReport(r)),
        };
    })

    // Verify report (pending -> terverifikasi) - Same as supervisor but separated for potential PJ-specific logic
    .post('/reports/:id/verify', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;
        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

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
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "PJ Gedung",
            actorRole: foundStaff[0]?.role || "pj_gedung",
            action: 'verified',
            fromStatus: 'pending',
            toStatus: 'terverifikasi',
            reason: body.notes || 'Laporan telah diverifikasi oleh PJ Gedung',
        });

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Laporan Diverifikasi', `Laporan "${updated[0].title}" telah diverifikasi oleh PJ Gedung.`);
        }

        // Notify Supervisor
        await NotificationService.notifyRole('supervisor', 'Laporan Terverifikasi', `Laporan baru di ${updated[0].building} telah diverifikasi oleh PJ Gedung.`);

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    });
