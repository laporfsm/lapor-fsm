import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, isNull } from 'drizzle-orm';

export const technicianController = new Elysia({ prefix: '/technician' })
    // Get all reports for technician (pending and assigned to this technician)
    .get('/reports/:staffId', async ({ params }) => {
        const staffId = parseInt(params.staffId);

        // Get reports that are either:
        // 1. Pending (not assigned yet)
        // 2. Assigned to this technician
        const reportsList = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                building: reports.building,
                latitude: reports.latitude,
                longitude: reports.longitude,
                imageUrl: reports.imageUrl,
                isEmergency: reports.isEmergency,
                status: reports.status,
                notes: reports.notes,
                createdAt: reports.createdAt,
                assignedTo: reports.assignedTo,
                assignedAt: reports.assignedAt,
                handledAt: reports.handledAt,
                // Reporter info
                reporterName: users.name,
                reporterPhone: users.phone,
                // Category info
                categoryName: categories.name,
                categoryType: categories.type,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(
                or(
                    eq(reports.status, 'pending'),
                    eq(reports.status, 'verifikasi'),
                    and(
                        eq(reports.assignedTo, staffId),
                        or(
                            eq(reports.status, 'penanganan'),
                            eq(reports.status, 'penanganan_ulang')
                        )
                    )
                )
            )
            .orderBy(desc(reports.isEmergency), desc(reports.createdAt));

        return {
            status: 'success',
            data: reportsList,
        };
    })

    // Verify a report (first step by teknisi)
    .post('/reports/:id/verify', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        // Update report status to verifikasi and assign to teknisi
        const updated = await db
            .update(reports)
            .set({
                status: 'verifikasi',
                assignedTo: staffId,
                assignedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        // Log the action
        await db.insert(reportLogs).values({
            reportId,
            staffId,
            action: 'verified',
            notes: body.notes || 'Laporan diverifikasi',
        });

        return {
            status: 'success',
            message: 'Laporan berhasil diverifikasi',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
            notes: t.Optional(t.String()),
        }),
    })

    // Start handling a report (teknisi on-site)
    .post('/reports/:id/handle', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        // Update report status to penanganan
        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan',
                handledAt: new Date(), // Start timer
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        // Log the action
        await db.insert(reportLogs).values({
            reportId,
            staffId,
            action: 'handling',
            notes: body.notes || 'Teknisi mulai menangani laporan',
        });

        return {
            status: 'success',
            message: 'Penanganan dimulai',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
            notes: t.Optional(t.String()),
        }),
    })

    // Complete a report (with proof photo)
    .post('/reports/:id/complete', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        // Update report status to selesai
        const updated = await db
            .update(reports)
            .set({
                status: 'selesai',
                completedAt: new Date(), // Stop timer
                handlerNotes: body.notes,
                handlerMediaUrl: body.mediaUrl, // Proof photo/video
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        // Log the action
        await db.insert(reportLogs).values({
            reportId,
            staffId,
            action: 'completed',
            notes: body.notes || 'Penanganan selesai',
        });

        return {
            status: 'success',
            message: 'Laporan selesai ditangani',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
            notes: t.Optional(t.String()),
            mediaUrl: t.String(), // Required proof
        }),
    })

    // Get single report detail
    .get('/reports/detail/:id', async ({ params }) => {
        const reportId = parseInt(params.id);

        const reportDetail = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                building: reports.building,
                latitude: reports.latitude,
                longitude: reports.longitude,
                imageUrl: reports.imageUrl,
                isEmergency: reports.isEmergency,
                status: reports.status,
                notes: reports.notes,
                handlerNotes: reports.handlerNotes,
                handlerMediaUrl: reports.handlerMediaUrl,
                createdAt: reports.createdAt,
                assignedAt: reports.assignedAt,
                handledAt: reports.handledAt,
                completedAt: reports.completedAt,
                // Reporter info
                reporterName: users.name,
                reporterPhone: users.phone,
                reporterEmail: users.email,
                // Category info
                categoryName: categories.name,
                categoryType: categories.type,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(eq(reports.id, reportId))
            .limit(1);

        if (reportDetail.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        // Get report logs
        const logs = await db
            .select({
                id: reportLogs.id,
                action: reportLogs.action,
                notes: reportLogs.notes,
                createdAt: reportLogs.createdAt,
                staffName: staff.name,
            })
            .from(reportLogs)
            .leftJoin(staff, eq(reportLogs.staffId, staff.id))
            .where(eq(reportLogs.reportId, reportId))
            .orderBy(desc(reportLogs.createdAt));

        return {
            status: 'success',
            data: {
                ...reportDetail[0],
                logs,
            },
        };
    });
