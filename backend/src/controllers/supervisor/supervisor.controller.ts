import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';

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

        const countsMap = statusCounts.reduce((acc, curr) => {
            acc[curr.status || 'unknown'] = curr.count;
            return acc;
        }, {} as Record<string, number>);

        // Time based counts
        const todayReports = await db.select({ count: count() }).from(reports).where(gte(reports.createdAt, startOfDay));
        const weekReports = await db.select({ count: count() }).from(reports).where(gte(reports.createdAt, startOfWeek));
        const monthReports = await db.select({ count: count() }).from(reports).where(gte(reports.createdAt, startOfMonth));

        // Emergency pending
        const emergencyCount = await db
            .select({ count: count() })
            .from(reports)
            .where(and(eq(reports.isEmergency, true), or(eq(reports.status, 'pending'), eq(reports.status, 'terverifikasi'))));

        // Recent reports
        const recentReports = await db
            .select({
                id: reports.id,
                title: reports.title,
                status: reports.status,
                createdAt: reports.createdAt,
            })
            .from(reports)
            .orderBy(desc(reports.createdAt))
            .limit(5);

        return {
            status: 'success',
            data: {
                pending: countsMap['pending'] || 0,
                verifikasi: (countsMap['terverifikasi'] || 0) + (countsMap['verifikasi'] || 0),
                penanganan: (countsMap['diproses'] || 0) + (countsMap['penanganan'] || 0),
                selesai: (countsMap['selesai'] || 0) + (countsMap['approved'] || 0),
                emergency: emergencyCount[0]?.count || 0,
                todayReports: todayReports[0]?.count || 0,
                weekReports: weekReports[0]?.count || 0,
                monthReports: monthReports[0]?.count || 0,
                recentReports: recentReports.map(r => ({ ...r, id: r.id.toString() })),
            },
        };
    })

    // Get all reports with filters
    .get('/reports', async ({ query }) => {
        const { status, building, isEmergency, page = '1', limit = '20' } = query;
        const pageNum = isNaN(parseInt(page)) ? 1 : parseInt(page);
        const limitNum = isNaN(parseInt(limit)) ? 20 : parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        let conditions = [];
        if (status && status !== 'all') conditions.push(eq(reports.status, status));
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
                mediaUrls: reports.mediaUrls,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                userId: reports.userId,
                // Detailed Info
                reporterName: users.name,
                categoryName: categories.name,
                handlerName: staff.name,
                supervisorName: sql<string>`(SELECT name FROM staff WHERE id = ${reports.approvedBy})`,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .where(whereClause)
            .orderBy(desc(reports.createdAt))
            .limit(limitNum)
            .offset(offset);

        return {
            status: 'success',
            data: result.map(r => mapToMobileReport(r)),
        };
    })

    // Verify report (pending -> terverifikasi)
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
            actorName: foundStaff[0]?.name || "Supervisor",
            actorRole: foundStaff[0]?.role || "supervisor",
            action: 'verified',
            fromStatus: 'pending',
            toStatus: 'terverifikasi',
            reason: body.notes || 'Laporan telah diverifikasi',
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    })

    // Assign technician (terverifikasi -> diproses)
    .post('/reports/:id/assign', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const supervisorId = body.supervisorId;
        const foundSupervisor = await db.select().from(staff).where(eq(staff.id, supervisorId)).limit(1);

        const updated = await db
            .update(reports)
            .set({
                status: 'diproses',
                assignedTo: body.technicianId,
                assignedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        await db.insert(reportLogs).values({
            reportId,
            actorId: supervisorId.toString(),
            actorName: foundSupervisor[0]?.name || "Supervisor",
            actorRole: foundSupervisor[0]?.role || "supervisor",
            action: 'handling',
            fromStatus: 'terverifikasi',
            toStatus: 'diproses',
            reason: `Laporan ditugaskan ke teknisi`,
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({
            supervisorId: t.Number(),
            technicianId: t.Number(),
        })
    })

    // Recall from Technician (any active state -> recalled)
    .post('/reports/:id/recall', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;
        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);

        const updated = await db
            .update(reports)
            .set({
                status: 'recalled',
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "Supervisor",
            actorRole: foundStaff[0]?.role || "supervisor",
            action: 'recalled',
            fromStatus: current[0].status || 'penanganan',
            toStatus: 'recalled',
            reason: body.reason,
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    })

    // Approve Completed Task (selesai -> approved)
    .post('/reports/:id/approve', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;
        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

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

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "Supervisor",
            actorRole: foundStaff[0]?.role || "supervisor",
            action: 'approved',
            fromStatus: 'selesai',
            toStatus: 'approved',
            reason: body.notes || 'Penanganan disetujui',
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    })

    // Reject Report (pending/terverifikasi -> ditolak)
    .post('/reports/:id/reject', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;
        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (current.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        const updated = await db
            .update(reports)
            .set({
                status: 'ditolak',
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        await db.insert(reportLogs).values({
            reportId,
            actorId: staffId.toString(),
            actorName: foundStaff[0]?.name || "Supervisor",
            actorRole: foundStaff[0]?.role || "supervisor",
            action: 'rejected',
            fromStatus: current[0].status || 'pending',
            toStatus: 'ditolak',
            reason: body.reason,
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    })

    // Export Reports to CSV
    .get('/reports/export', async ({ query }) => {
        const { status, building } = query;
        
        let conditions = [];
        if (status && status !== 'all') conditions.push(eq(reports.status, status));
        if (building) conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                status: reports.status,
                building: reports.building,
                createdAt: reports.createdAt,
            })
            .from(reports)
            .where(whereClause)
            .orderBy(desc(reports.createdAt));

        // Create CSV
        const header = "ID,Title,Status,Building,CreatedAt\n";
        const rows = result.map(r => 
            `${r.id},"${r.title.replace(/"/g, '""')}","${r.status}","${r.building}","${r.createdAt?.toISOString()}"`
        ).join("\n");

        return new Response(header + rows, {
            headers: {
                'Content-Type': 'text/csv',
                'Content-Disposition': 'attachment; filename="reports_export.csv"'
            }
        });
    })

    // Get all technicians (for assignment/management)
    .get('/technicians', async () => {
        const techs = await db
            .select({
                id: staff.id,
                name: staff.name,
                email: staff.email,
                phone: staff.phone,
                specialization: staff.specialization,
                isActive: staff.isActive,
            })
            .from(staff)
            .where(eq(staff.role, 'teknisi'))
            .orderBy(staff.name);

        return {
            status: 'success',
            data: techs.map(t => ({ ...t, id: t.id.toString() })),
        };
    });
