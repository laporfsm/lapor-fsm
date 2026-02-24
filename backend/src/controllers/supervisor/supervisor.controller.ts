import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories, locations } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte, isNull, inArray } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';
import { logEventEmitter, LOG_EVENTS } from '../../utils/events';

import { getStartOfWeek, getStartOfMonth, getStartOfDay } from '../../utils/date.utils';

export const supervisorController = new Elysia({ prefix: '/supervisor' })
    // Dashboard statistics
    .get('/dashboard/:staffId', async ({ params }) => {
        const startOfDay = getStartOfDay();
        const startOfWeek = getStartOfWeek();
        const startOfMonth = getStartOfMonth();

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

        // Emergency: All emergency reports except approved
        const emergencyCount = await db
            .select({ count: count() })
            .from(reports)
            .where(and(
                eq(reports.isEmergency, true),
                sql`${reports.status} != 'approved'`
            ));

        // Get all managed locations (locations that have a PJ Gedung)
        const managedLocations = await db
            .select({ location: staff.managedLocation })
            .from(staff)
            .where(sql`${staff.managedLocation} IS NOT NULL AND ${staff.managedLocation} != ''`);

        const managedLocationList = managedLocations.map(l => l.location).filter(Boolean) as string[];

        // Non-Gedung Pending: Reports with status 'pending' in locations without a PJ Gedung
        let nonGedungPendingCount = 0;
        if (managedLocationList.length > 0) {
            const nonGedungResult = await db
                .select({ count: count() })
                .from(reports)
                .where(and(
                    eq(reports.status, 'pending'),
                    sql`${reports.location} NOT IN (${sql.join(managedLocationList.map(l => sql`${l}`), sql`, `)})`
                ));
            nonGedungPendingCount = nonGedungResult[0]?.count || 0;
        } else {
            // If no managed locations, all pending reports are "non-gedung"
            nonGedungPendingCount = countsMap['pending'] || 0;
        }

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
                // Individual status counts (9 statuses)
                pending: countsMap['pending'] || 0,
                terverifikasi: countsMap['terverifikasi'] || 0,
                diproses: countsMap['diproses'] || 0,
                penanganan: countsMap['penanganan'] || 0,
                onHold: countsMap['onHold'] || 0,
                selesai: countsMap['selesai'] || 0,
                recalled: countsMap['recalled'] || 0,
                approved: countsMap['approved'] || 0,
                ditolak: countsMap['ditolak'] || 0,
                // Special counts
                emergency: emergencyCount[0]?.count || 0,
                nonGedungPending: nonGedungPendingCount,
                // Period counts
                todayReports: todayReports[0]?.count || 0,
                weekReports: weekReports[0]?.count || 0,
                monthReports: monthReports[0]?.count || 0,
                recentReports: recentReports.map(r => ({ ...r, id: r.id.toString() })),
            },
        };
    })

    // Get all reports with filters
    .get('/reports', async ({ query }) => {
        const { status, location, isEmergency, page = '1', limit = '50' } = query;
        console.log('[DEBUG] Supervisor /reports endpoint - status query:', status);
        const pageNum = isNaN(parseInt(page)) ? 1 : parseInt(page);
        const limitNum = isNaN(parseInt(limit)) ? 50 : parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        let conditions = [];

        // Support multiple statuses separated by comma (e.g., 'pending,terverifikasi')
        if (status && status !== 'all') {
            const statusList = status.split(',').map(s => s.trim());
            if (statusList.length > 1) {
                console.log('[DEBUG] Multiple statuses found:', statusList);
                conditions.push(or(...statusList.map(s => eq(reports.status, s))));
            } else {
                console.log('[DEBUG] Single status:', statusList[0]);
                conditions.push(eq(reports.status, statusList[0]));
            }
        }

        if (location) conditions.push(sql`${reports.location} ILIKE ${'%' + location + '%'}`);
        if (isEmergency === 'true') conditions.push(eq(reports.isEmergency, true));

        // Hide child reports from main list
        conditions.push(isNull(reports.parentId));

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const verifierStaff = alias(staff, 'verifier_staff');

        // Get total count for pagination
        const totalResult = await db
            .select({ count: count() })
            .from(reports)
            .where(whereClause);

        const totalCount = totalResult[0]?.count || 0;

        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                location: reports.location,
                locationDetail: reports.locationDetail,
                mediaUrls: reports.mediaUrls,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                userId: reports.userId,
                // Completion tracking
                handlingCompletedAt: reports.handlingCompletedAt,
                // Detailed Info
                reporterName: users.name,
                reporterEmail: users.email,
                categoryName: categories.name,
                handlerName: staff.name,
                approvedBy: reports.approvedBy,
                verifiedBy: reports.verifiedBy,
                supervisorName: verifierStaff.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .leftJoin(staff, eq(reports.assignedTo, staff.id))
            .leftJoin(verifierStaff, sql`${verifierStaff.id} = COALESCE(${reports.approvedBy}, ${reports.verifiedBy})`)
            .where(whereClause)
            .orderBy(desc(reports.createdAt))
            .limit(limitNum)
            .offset(offset);

        console.log('[DEBUG] Query result count:', result.length, 'for status:', status);
        if (result.length > 0) {
            console.log('[DEBUG] First result sample:', JSON.stringify(result[0], null, 2));
        }

        return {
            status: 'success',
            data: result.map(r => mapToMobileReport(r)),
            total: totalCount
        };
    })

    // Get Non-Gedung pending reports (locations without PJ Gedung)
    .get('/reports/non-gedung', async ({ query }) => {
        const { limit = '20' } = query;
        const limitNum = isNaN(parseInt(limit)) ? 20 : parseInt(limit);

        // Get all managed locations
        const managedLocations = await db
            .select({ location: staff.managedLocation })
            .from(staff)
            .where(sql`${staff.managedLocation} IS NOT NULL AND ${staff.managedLocation} != ''`);

        const managedLocationList = managedLocations.map(l => l.location).filter(Boolean) as string[];

        let conditions = [
            eq(reports.status, 'pending'),
            isNull(reports.parentId),
        ];

        if (managedLocationList.length > 0) {
            conditions.push(sql`${reports.location} NOT IN (${sql.join(managedLocationList.map(l => sql`${l}`), sql`, `)})`);
        }

        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                location: reports.location,
                locationDetail: reports.locationDetail,
                mediaUrls: reports.mediaUrls,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                userId: reports.userId,
                reporterName: users.name,
                categoryName: categories.name,
                approvedBy: reports.approvedBy,
                verifiedBy: reports.verifiedBy,
                supervisorName: sql<string>`(SELECT name FROM staff WHERE id = COALESCE(${reports.approvedBy}, ${reports.verifiedBy}))`,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(and(...conditions))
            .orderBy(desc(reports.createdAt))
            .limit(limitNum);

        return {
            status: 'success',
            data: result.map(r => mapToMobileReport(r)),
            count: result.length,
        };
    })

    // Verify report (pending -> terverifikasi)
    .post('/reports/:id/verify', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        try {
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

            logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

            // Notify User
            if (updated[0].userId) {
                await NotificationService.notifyUser(updated[0].userId, 'Laporan Diverifikasi', `Laporan "${updated[0].title}" telah diverifikasi.`, 'info', reportId);
            }

            return {
                status: 'success',
                data: mapToMobileReport({
                    ...updated[0],
                    supervisorName: foundStaff[0]?.name
                })
            };
        } catch (e: any) {
            console.error('Verify Report Error:', e);
            return { status: 'error', message: 'Gagal memverifikasi laporan: ' + e.message };
        }
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    })

    // Assign technician (terverifikasi -> diproses)
    .post('/reports/:id/assign', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const supervisorId = body.supervisorId;

        try {
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

            logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

            // Notify Technician
            await NotificationService.notifyStaff(body.technicianId, 'Tugas Baru', `Anda ditugaskan menangani laporan: ${updated[0].title}`, 'info', reportId);

            // Notify User
            if (updated[0].userId) {
                await NotificationService.notifyUser(updated[0].userId, 'Laporan Diproses', `Teknisi sedang menangani laporan Anda.`, 'info', reportId);
            }

            return {
                status: 'success',
                data: mapToMobileReport({
                    ...updated[0],
                    supervisorName: foundSupervisor[0]?.name
                })
            };
        } catch (e: any) {
            console.error('Assign Report Error:', e);
            return { status: 'error', message: 'Gagal menugaskan laporan: ' + e.message };
        }
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

        try {
            const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);
            const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);

            if (current.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

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

            logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

            // Notify Pelapor (Reporter) about recall
            if (current[0].userId) {
                await NotificationService.notifyUser(
                    current[0].userId,
                    'Laporan Ditarik Kembali',
                    `Laporan "${current[0].title}" sedang ditinjau ulang oleh Supervisor. Mohon menunggu hasil peninjauan.`,
                    'warning',
                    reportId
                );
            }

            // Notify Technician (if assigned)
            if (current[0].assignedTo) {
                await NotificationService.notifyStaff(
                    current[0].assignedTo,
                    'Tugas Dibatalkan/Direvisi',
                    `Tugas "${current[0].title}" telah ditarik kembali oleh Supervisor untuk peninjauan ulang.`,
                    'warning',
                    reportId
                );
            }

            return { status: 'success', data: mapToMobileReport(updated[0]) };
        } catch (e: any) {
            console.error('Recall Report Error:', e);
            return { status: 'error', message: 'Gagal menarik kembali laporan: ' + e.message };
        }
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    })

    // Approve Completed Task (selesai -> approved)
    .post('/reports/:id/approve', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        try {
            const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);
            if (foundStaff.length === 0) {
                return { status: 'error', message: 'Staff Supervisor tidak ditemukan' };
            }

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

            if (updated.length === 0) {
                return { status: 'error', message: 'Laporan tidak ditemukan' };
            }

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

            logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

            // Notify User
            if (updated[0].userId) {
                await NotificationService.notifyUser(updated[0].userId, 'Laporan Selesai', `Laporan Anda telah selesai dan disetujui.`, 'success', reportId);
            }

            return {
                status: 'success',
                data: mapToMobileReport({
                    ...updated[0],
                    supervisorName: foundStaff[0]?.name
                })
            };
        } catch (e: any) {
            console.error('Approve Report Error:', e);
            return { status: 'error', message: 'Gagal menyetujui laporan: ' + e.message };
        }
    }, {
        body: t.Object({ staffId: t.Number(), notes: t.Optional(t.String()) })
    })

    // Reject Report (pending/terverifikasi -> ditolak)
    .post('/reports/:id/reject', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        try {
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

            logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

            // Notify User
            if (updated[0].userId) {
                await NotificationService.notifyUser(updated[0].userId, 'Laporan Ditolak', `Maaf, laporan Anda ditolak: ${body.reason}`, 'warning', reportId);
            }

            return { status: 'success', data: mapToMobileReport(updated[0]) };
        } catch (e: any) {
            console.error('Reject Report Error:', e);
            return { status: 'error', message: 'Gagal menolak laporan: ' + e.message };
        }
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    })

    // Group Reports (Combine multiple reports into one Parent)
    .post('/reports/group', async ({ body }) => {
        const { reportIds, staffId, notes } = body;

        if (!reportIds || reportIds.length < 2) {
            return { status: 'error', message: 'Minimal 2 laporan untuk penggabungan.' };
        }

        // Get all reports to be grouped
        const targets = await db
            .select()
            .from(reports)
            .where(inArray(reports.id, reportIds))
            .orderBy(reports.createdAt);

        if (targets.length !== reportIds.length) {
            return { status: 'error', message: 'Beberapa laporan tidak ditemukan.' };
        }

        // Validate: All reports must be in triage status (Pending/Verified)
        // Prevent merging already assigned/processed reports
        const invalidStatus = targets.find(r =>
            !['pending', 'terverifikasi', 'verifikasi'].includes(r.status || '')
        );

        if (invalidStatus) {
            return {
                status: 'error',
                message: `Laporan #${invalidStatus.id} sudah diproses/selesai. Hanya laporan Pending/Terverifikasi yang bisa digabung.`
            };
        }

        // Validate: All reports must be from the same Building/Location
        const firstLocation = targets[0].location;
        const differentLocation = targets.find(r => r.location !== firstLocation);

        if (differentLocation) {
            return {
                status: 'error',
                message: 'Semua laporan harus berasal dari lokasi yang sama.'
            };
        }

        // Validate: Reports must not be already merged (Child)
        const alreadyChild = targets.find(r => r.parentId != null);
        if (alreadyChild) {
            return {
                status: 'error',
                message: `Laporan #${alreadyChild.id} sudah merupakan bagian dari gabungan lain.`
            };
        }

        // Designate the oldest (first) as Master/Parent
        const parent = targets[0];
        const children = targets.slice(1);
        const childIds = children.map(c => c.id);

        if (childIds.length > 0) {
            // Update Children: Set parentId and status to 'recalled' (hidden/merged)
            await db
                .update(reports)
                .set({
                    parentId: parent.id,
                    status: 'recalled', // Mark as recalled/merged
                    updatedAt: new Date(),
                })
                .where(inArray(reports.id, childIds));

            // Log for Children
            for (const child of children) {
                await db.insert(reportLogs).values({
                    reportId: child.id,
                    actorId: staffId.toString(),
                    actorName: "Supervisor",
                    actorRole: "supervisor",
                    action: 'groupedChild',
                    toStatus: 'recalled',
                    reason: `Digabungkan ke laporan #${parent.id}`,
                });
            }
        }

        // Log for Parent
        await db.insert(reportLogs).values({
            reportId: parent.id,
            actorId: staffId.toString(),
            actorName: "Supervisor",
            actorRole: "supervisor",
            action: 'grouped',
            toStatus: parent.status || 'pending',
            reason: notes || `Digabungkan dengan ${children.length} laporan lain.`,
        });

        logEventEmitter.emit(LOG_EVENTS.NEW_LOG, parent.id);
        for (const childId of childIds) {
            logEventEmitter.emit(LOG_EVENTS.NEW_LOG, childId);
        }

        return {
            status: 'success',
            data: mapToMobileReport(parent),
            message: `Berhasil menggabungkan ${reportIds.length} laporan.`
        };
    }, {
        body: t.Object({
            reportIds: t.Array(t.Number()),
            staffId: t.Number(),
            notes: t.Optional(t.String()),
        })
    })

    // Export Reports to CSV
    .get('/reports/export', async ({ query }) => {
        const { status, location } = query;

        let conditions = [];
        if (status && status !== 'all') conditions.push(eq(reports.status, status));
        if (location) conditions.push(sql`${reports.location} ILIKE ${'%' + location + '%'}`);

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                status: reports.status,
                location: reports.location,
                createdAt: reports.createdAt,
            })
            .from(reports)
            .where(whereClause)
            .orderBy(desc(reports.createdAt));

        // Create CSV
        const header = "ID,Title,Status,Location,CreatedAt\n";
        const rows = result.map(r =>
            `${r.id},"${r.title.replace(/"/g, '""')}","${r.status}","${r.location}","${r.createdAt?.toISOString()}"`
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
    })

    // Get all PJ Gedung
    .get('/pj-gedung', async () => {
        const pjs = await db
            .select({
                id: staff.id,
                name: staff.name,
                email: staff.email,
                phone: staff.phone,
                isActive: staff.isActive,
                managedLocation: staff.managedLocation,
            })
            .from(staff)
            .where(eq(staff.role, 'pj_gedung'))
            .orderBy(staff.managedLocation);

        return {
            status: 'success',
            data: pjs.map(p => ({
                ...p,
                id: p.id.toString(),
                location: p.managedLocation,
            })),
        };
    })

    // Get PJ Gedung detail
    .get('/pj-gedung/:id', async ({ params }) => {
        const staffId = parseInt(params.id);
        const pj = await db
            .select({
                id: staff.id,
                name: staff.name,
                email: staff.email,
                phone: staff.phone,
                role: staff.role,
                isActive: staff.isActive,
                managedLocation: staff.managedLocation,
                createdAt: staff.createdAt,
            })
            .from(staff)
            .where(and(eq(staff.id, staffId), eq(staff.role, 'pj_gedung')))
            .limit(1);

        if (pj.length === 0) {
            return { status: 'error', message: 'PJ Gedung tidak ditemukan' };
        }

        return {
            status: 'success',
            data: {
                ...pj[0],
                id: pj[0].id.toString(),
            }
        };
    })

    // Get technician detail
    .get('/technicians/:id', async ({ params }) => {
        const staffId = parseInt(params.id);
        const technician = await db
            .select({
                id: staff.id,
                name: staff.name,
                email: staff.email,
                phone: staff.phone,
                specialization: staff.specialization,
                role: staff.role,
                isActive: staff.isActive,
                createdAt: staff.createdAt,
            })
            .from(staff)
            .where(eq(staff.id, staffId))
            .limit(1);

        if (technician.length === 0) {
            return { status: 'error', message: 'Teknisi tidak ditemukan' };
        }

        // Mock stats and logs if not available yet (for frontend compatibility)
        // In real app, we would query stats from reports table.
        return {
            status: 'success',
            data: {
                ...technician[0],
                id: technician[0].id.toString(),
                stats: {
                    completed: 0, // Placeholder
                    inProgress: 0,
                    avgTime: '-',
                },
                logs: [], // Placeholder
            }
        };
    })

    // ===========================================================================
    // TECHNICIAN CRUD
    // ===========================================================================

    // Create Technician
    .post('/technicians', async ({ body }) => {
        // Validate if email exists
        const existing = await db.select().from(staff).where(eq(staff.email, body.email)).limit(1);
        if (existing.length > 0) {
            return { status: 'error', message: 'Email sudah terdaftar (Supervisor/Teknisi/PJ).' };
        }

        // Default password or provided
        const plainPassword = body.password || 'teknisi123';
        const hashedPassword = await Bun.password.hash(plainPassword);

        try {
            const newStaff = await db.insert(staff).values({
                name: body.name,
                email: body.email,
                phone: body.phone,
                role: 'teknisi',
                specialization: body.specialization || 'Umum',
                password: hashedPassword,
                isActive: true,
            }).returning();

            return {
                status: 'success',
                data: { ...newStaff[0], id: newStaff[0].id.toString() },
                message: 'Teknisi berhasil ditambahkan'
            };
        } catch (e: any) {
            console.error('Create Technician Error:', e);
            return { status: 'error', message: 'Gagal menambahkan teknisi: ' + e.message };
        }
    }, {
        body: t.Object({
            name: t.String({ minLength: 2 }),
            email: t.String(),
            phone: t.String(),
            specialization: t.String(),
            password: t.Optional(t.String()),
        })
    })

    // Update Technician
    .put('/technicians/:id', async ({ params, body }) => {
        const staffId = parseInt(params.id);

        try {
            const updated = await db
                .update(staff)
                .set({
                    name: body.name,
                    email: body.email,
                    phone: body.phone,
                    specialization: body.specialization,
                })
                .where(eq(staff.id, staffId))
                .returning();

            if (updated.length === 0) {
                return { status: 'error', message: 'Teknisi tidak ditemukan' };
            }

            return {
                status: 'success',
                data: { ...updated[0], id: updated[0].id.toString() },
                message: 'Data teknisi berhasil diperbarui'
            };
        } catch (e: any) {
            console.error('Update Technician Error:', e);
            return { status: 'error', message: 'Gagal memperbarui teknisi: ' + e.message };
        }
    }, {
        body: t.Object({
            name: t.String(),
            email: t.String(),
            phone: t.String(),
            specialization: t.String(),
        })
    })

    // Delete Technician
    .delete('/technicians/:id', async ({ params }) => {
        const staffId = parseInt(params.id);

        try {
            const deleted = await db.delete(staff).where(and(eq(staff.id, staffId), eq(staff.role, 'teknisi'))).returning();

            if (deleted.length === 0) {
                return { status: 'error', message: 'Teknisi tidak ditemukan' };
            }

            return { status: 'success', message: 'Teknisi berhasil dihapus' };
        } catch (e: any) {
            console.error('Delete Technician Error:', e);
            return { status: 'error', message: 'Gagal menghapus teknisi (mungkin sedang menangani laporan).' };
        }
    })

    // ===========================================================================
    // PJ GEDUNG CRUD
    // ===========================================================================

    // Create PJ Gedung
    .post('/pj-gedung', async ({ body }) => {
        const existing = await db.select().from(staff).where(eq(staff.email, body.email)).limit(1);
        if (existing.length > 0) {
            return { status: 'error', message: 'Email sudah terdaftar.' };
        }

        const plainPassword = body.password || 'pjgedung123';
        const hashedPassword = await Bun.password.hash(plainPassword);

        try {
            const newStaff = await db.insert(staff).values({
                name: body.name,
                email: body.email,
                phone: body.phone,
                role: 'pj_gedung',
                managedLocation: body.managedLocation,
                password: hashedPassword,
                isActive: true,
            }).returning();

            return {
                status: 'success',
                data: { ...newStaff[0], id: newStaff[0].id.toString() },
                message: 'PJ Gedung berhasil ditambahkan'
            };
        } catch (e: any) {
            console.error('Create PJ Gedung Error:', e);
            return { status: 'error', message: 'Gagal menambahkan PJ Gedung: ' + e.message };
        }
    }, {
        body: t.Object({
            name: t.String({ minLength: 2 }),
            email: t.String(),
            phone: t.String(),
            managedLocation: t.String(),
            password: t.Optional(t.String()),
        })
    })

    // Update PJ Gedung
    .put('/pj-gedung/:id', async ({ params, body }) => {
        const staffId = parseInt(params.id);

        try {
            const updated = await db
                .update(staff)
                .set({
                    name: body.name,
                    email: body.email,
                    phone: body.phone,
                    managedLocation: body.managedLocation,
                })
                .where(and(eq(staff.id, staffId), eq(staff.role, 'pj_gedung')))
                .returning();

            if (updated.length === 0) {
                return { status: 'error', message: 'PJ Gedung tidak ditemukan' };
            }

            return {
                status: 'success',
                data: { ...updated[0], id: updated[0].id.toString() },
                message: 'Data PJ Gedung berhasil diperbarui'
            };
        } catch (e: any) {
            console.error('Update PJ Gedung Error:', e);
            return { status: 'error', message: 'Gagal memperbarui PJ Gedung: ' + e.message };
        }
    }, {
        body: t.Object({
            name: t.String(),
            email: t.String(),
            phone: t.String(),
            managedLocation: t.String(),
        })
    })

    // Delete PJ Gedung
    .delete('/pj-gedung/:id', async ({ params }) => {
        const staffId = parseInt(params.id);

        try {
            const deleted = await db.delete(staff).where(and(eq(staff.id, staffId), eq(staff.role, 'pj_gedung'))).returning();

            if (deleted.length === 0) {
                return { status: 'error', message: 'PJ Gedung tidak ditemukan' };
            }

            return { status: 'success', message: 'PJ Gedung berhasil dihapus' };
        } catch (e: any) {
            console.error('Delete PJ Gedung Error:', e);
            return { status: 'error', message: 'Gagal menghapus PJ Gedung.' };
        }
    })

    // ===========================================================================
    // REJECTED REPORTS ACTIONS
    // ===========================================================================

    // Archive Report (Change status to 'archived')
    .post('/reports/:id/archive', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        try {
            const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);
            if (foundStaff.length === 0) return { status: 'error', message: 'Staff tidak ditemukan' };

            const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
            if (current.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

            // Ensure report is rejected before archiving
            if (current[0].status !== 'ditolak') {
                return { status: 'error', message: 'Hanya laporan dengan status "ditolak" yang dapat diarsipkan.' };
            }

            const updated = await db.update(reports)
                .set({
                    status: 'archived' as any,
                    updatedAt: new Date(),
                })
                .where(eq(reports.id, reportId))
                .returning();

            // Insert Log
            await db.insert(reportLogs).values({
                reportId,
                actorId: staffId.toString(),
                actorName: foundStaff[0]?.name || "Supervisor",
                actorRole: foundStaff[0]?.role || "supervisor",
                action: 'archived',
                fromStatus: 'ditolak',
                toStatus: 'archived',
                reason: 'Laporan ditolak telah diarsipkan oleh supervisor',
            });

            return { status: 'success', data: mapToMobileReport(updated[0]) };
        } catch (e: any) {
            console.error('Archive Report Error:', e);
            return { status: 'error', message: 'Gagal mengarsipkan laporan.' };
        }
    }, {
        body: t.Object({ staffId: t.Number() })
    })

    // Return Report to Queue (Change status back to 'pending')
    .post('/reports/:id/return-to-queue', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        try {
            const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);
            if (foundStaff.length === 0) return { status: 'error', message: 'Staff tidak ditemukan' };

            const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
            if (current.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

            const updated = await db.update(reports)
                .set({
                    status: 'pending',
                    assignedTo: null, // Clear assignment
                    updatedAt: new Date(),
                })
                .where(eq(reports.id, reportId))
                .returning();

            // Insert Log
            await db.insert(reportLogs).values({
                reportId,
                actorId: staffId.toString(),
                actorName: foundStaff[0]?.name || "Supervisor",
                actorRole: foundStaff[0]?.role || "supervisor",
                action: 'recalled', // Or a new action if preferred, but recalled fits reverting assignment
                fromStatus: current[0].status || 'ditolak',
                toStatus: 'pending',
                reason: 'Penolakan dibatalkan, laporan dikembalikan ke antrian',
            });

            return { status: 'success', data: mapToMobileReport(updated[0]) };
        } catch (e: any) {
            console.error('Return to Queue Error:', e);
            return { status: 'error', message: 'Gagal mengembalikan laporan ke antrian.' };
        }
    }, {
        body: t.Object({ staffId: t.Number() })
    })

    // Get detailed statistics (for SupervisorStatisticsPage)
    .get('/statistics', async () => {
        // 1. Weekly Stats (Pending, Diproses, Selesai)
        const startOfWeek = new Date();
        startOfWeek.setDate(startOfWeek.getDate() - 7);
        startOfWeek.setHours(0, 0, 0, 0);

        const weeklyStats = await db.select({
            status: reports.status,
            count: count()
        })
            .from(reports)
            .where(gte(reports.createdAt, startOfWeek))
            .groupBy(reports.status);

        const weeklyMap = weeklyStats.reduce((acc, curr) => {
            acc[curr.status || 'unknown'] = curr.count;
            return acc;
        }, {} as Record<string, number>);

        // 2. Category Breakdown
        const categoryStats = await db.select({
            name: categories.name,
            count: count()
        })
            .from(reports)
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .groupBy(categories.name);

        const totalReports = categoryStats.reduce((sum, c) => sum + c.count, 0);
        const categoriesData = categoryStats.map(c => ({
            label: c.name || 'Lainnya',
            count: c.count,
            percentage: totalReports > 0 ? (c.count / totalReports) : 0
        }));

        // 3. Issues by Location
        const locationStats = await db.select({
            location: reports.location,
            count: count()
        })
            .from(reports)
            .where(and(
                sql`${reports.location} IS NOT NULL`,
                sql`${reports.location} != ''`
            ))
            .groupBy(reports.location)
            .orderBy(desc(count()))
            .limit(5);

        // 4. Daily Trends (Last 7 Days)
        const dailyRaw = await db.select({
            dateStr: sql<string>`TO_CHAR(${reports.createdAt}, 'YYYY-MM-DD')`,
            count: count()
        })
            .from(reports)
            .where(gte(reports.createdAt, startOfWeek))
            .groupBy(sql`TO_CHAR(${reports.createdAt}, 'YYYY-MM-DD')`)
            .orderBy(sql`TO_CHAR(${reports.createdAt}, 'YYYY-MM-DD')`);

        const dailyMap = dailyRaw.reduce((acc, curr) => {
            acc[curr.dateStr] = Number(curr.count);
            return acc;
        }, {} as Record<string, number>);

        const dailyTrends = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dateStr = d.toISOString().split('T')[0];
            dailyTrends.push({
                day: d.toLocaleDateString('id-ID', { weekday: 'short' }),
                value: dailyMap[dateStr] || 0
            });
        }

        // 5. Technician Performance (Top based on completed reports)
        const techStats = await db.select({
            id: staff.id,
            name: staff.name,
            isActive: staff.isActive,
            completedCount: count(reports.id)
        })
            .from(staff)
            .leftJoin(reports, and(
                eq(reports.assignedTo, staff.id),
                sql`${reports.status} IN ('selesai', 'approved')`
            ))
            .where(eq(staff.role, 'teknisi'))
            .groupBy(staff.id, staff.name, staff.isActive)
            .orderBy(desc(count(reports.id)))
            .limit(10);

        const technicianPerformances = techStats.map(t => ({
            id: t.id.toString(),
            name: t.name,
            status: t.isActive ? 'Bekerja' : 'Off',
            completedCount: t.completedCount
        }));

        return {
            status: 'success',
            data: {
                summary: [
                    { label: 'Pending', value: weeklyMap['pending'] || 0, color: 'grey' },
                    { label: 'Diproses', value: (weeklyMap['diproses'] || 0) + (weeklyMap['terverifikasi'] || 0) + (weeklyMap['penanganan'] || 0), color: 'blue' },
                    { label: 'Selesai', value: (weeklyMap['selesai'] || 0) + (weeklyMap['approved'] || 0), color: 'green' },
                ],
                categories: categoriesData,
                locations: locationStats.map(l => ({
                    name: l.location,
                    count: l.count
                })),
                dailyTrends,
                technicians: technicianPerformances
            }
        };
    })
    // Get all locations with active report counts
    .get('/locations', async () => {
        // Get all locations from the master table
        const allLocations = await db.select().from(locations);

        // Count active reports per location
        const activeReportCounts = await db
            .select({
                location: reports.location,
                count: count(),
            })
            .from(reports)
            .where(and(
                sql`${reports.status} NOT IN ('selesai', 'approved', 'ditolak', 'archived', 'recalled')`
            ))
            .groupBy(reports.location);

        const countsMap = activeReportCounts.reduce((acc, curr) => {
            if (curr.location) acc[curr.location] = curr.count;
            return acc;
        }, {} as Record<string, number>);

        const data = allLocations.map(l => ({
            name: l.name,
            reports: countsMap[l.name] || 0,
            status: (countsMap[l.name] || 0) > 10 ? 'Critical' : (countsMap[l.name] || 0) > 5 ? 'Warning' : 'Safe'
        }));

        // Also add reports from locations not in the master table (if any)
        const masterLocationNames = new Set(allLocations.map(l => l.name));
        activeReportCounts.forEach(c => {
            if (c.location && !masterLocationNames.has(c.location)) {
                data.push({
                    name: c.location,
                    reports: c.count,
                    status: c.count > 10 ? 'Critical' : c.count > 5 ? 'Warning' : 'Safe'
                });
            }
        });

        return {
            status: 'success',
            data: data.sort((a, b) => b.reports - a.reports)
        };
    });
