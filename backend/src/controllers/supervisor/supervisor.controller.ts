import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte, isNull, inArray } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';

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

        // Get all managed buildings (buildings that have a PJ Gedung)
        const managedBuildings = await db
            .select({ building: staff.managedBuilding })
            .from(staff)
            .where(sql`${staff.managedBuilding} IS NOT NULL AND ${staff.managedBuilding} != ''`);

        const managedBuildingList = managedBuildings.map(b => b.building).filter(Boolean) as string[];

        // Non-Gedung Pending: Reports with status 'pending' in buildings without a PJ Gedung
        let nonGedungPendingCount = 0;
        if (managedBuildingList.length > 0) {
            const nonGedungResult = await db
                .select({ count: count() })
                .from(reports)
                .where(and(
                    eq(reports.status, 'pending'),
                    sql`${reports.building} NOT IN (${sql.join(managedBuildingList.map(b => sql`${b}`), sql`, `)})`
                ));
            nonGedungPendingCount = nonGedungResult[0]?.count || 0;
        } else {
            // If no managed buildings, all pending reports are "non-gedung"
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
        const { status, building, isEmergency, page = '1', limit = '20' } = query;
        console.log('[DEBUG] Supervisor /reports endpoint - status query:', status);
        const pageNum = isNaN(parseInt(page)) ? 1 : parseInt(page);
        const limitNum = isNaN(parseInt(limit)) ? 20 : parseInt(limit);
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

        if (building) conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
        if (isEmergency === 'true') conditions.push(eq(reports.isEmergency, true));

        // Hide child reports from main list
        conditions.push(isNull(reports.parentId));

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const verifierStaff = alias(staff, 'verifier_staff');

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
        };
    })

    // Get Non-Gedung pending reports (buildings without PJ Gedung)
    .get('/reports/non-gedung', async ({ query }) => {
        const { limit = '20' } = query;
        const limitNum = isNaN(parseInt(limit)) ? 20 : parseInt(limit);

        // Get all managed buildings
        const managedBuildings = await db
            .select({ building: staff.managedBuilding })
            .from(staff)
            .where(sql`${staff.managedBuilding} IS NOT NULL AND ${staff.managedBuilding} != ''`);

        const managedBuildingList = managedBuildings.map(b => b.building).filter(Boolean) as string[];

        let conditions = [
            eq(reports.status, 'pending'),
            isNull(reports.parentId),
        ];

        if (managedBuildingList.length > 0) {
            conditions.push(sql`${reports.building} NOT IN (${sql.join(managedBuildingList.map(b => sql`${b}`), sql`, `)})`);
        }

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

        // Notify Technician (if assigned)
        if (current[0].assignedTo) {
            await NotificationService.notifyStaff(current[0].assignedTo, 'Tugas Dibatalkan', `Tugas "${current[0].title}" telah ditarik kembali oleh Supervisor.`, 'warning', reportId);
        }

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

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Laporan Ditolak', `Maaf, laporan Anda ditolak: ${body.reason}`, 'warning', reportId);
        }

        return { status: 'success', data: mapToMobileReport(updated[0]) };
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
        const firstBuilding = targets[0].building;
        const differentBuilding = targets.find(r => r.building !== firstBuilding);

        if (differentBuilding) {
            return {
                status: 'error',
                message: 'Semua laporan harus berasal dari lokasi/gedung yang sama.'
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
            actorName: "Supervisor", // Ideally fetch name
            actorRole: "supervisor",
            action: 'grouped',
            toStatus: parent.status || 'pending',
            reason: notes || `Digabungkan dengan ${children.length} laporan lain.`,
        });

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
    })

    // Get all PJ Gedung
    .get('/pj-gedung', async () => {
        const pjs = await db
            .select({
                id: staff.id,
                name: staff.name,
                email: staff.email,
                phone: staff.phone, // Include phone
                isActive: staff.isActive,
                managedBuilding: staff.managedBuilding,
            })
            .from(staff)
            .where(eq(staff.role, 'pj_gedung'))
            .orderBy(staff.managedBuilding);

        return {
            status: 'success',
            data: pjs.map(p => ({
                ...p,
                id: p.id.toString(),
                // Use managedBuilding as location
                location: p.managedBuilding,
            })),
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
            // Check dependency: reports assigned to this technician?
            // For now, simple delete. If foreign key constraint exists, it will throw.
            // We could also Soft Delete (isActive = false).
            // Let's try simple delete first as requested.

            const deleted = await db.delete(staff).where(eq(staff.id, staffId)).returning();

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
    });
