import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, isNull } from 'drizzle-orm';

export const technicianController = new Elysia({ prefix: '/technician' })
    // Get all reports for technician (pending and assigned to this technician)
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
                assignedTo: reports.assignedTo,
                assignedAt: reports.assignedAt,
                handlingStartedAt: reports.handlingStartedAt,
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
                    eq(reports.status, 'terverifikasi'),
                    and(
                        eq(reports.assignedTo, staffId),
                        or(
                            eq(reports.status, 'penanganan'),
                            eq(reports.status, 'diproses')
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

    // Start handling a report (Accepting the task)
    .post('/reports/:id/accept', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                status: 'penanganan',
                assignedTo: staffId,
                assignedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: staffId,
            action: 'assigned',
            fromStatus: updated[0].status || 'pending',
            toStatus: 'penanganan',
            notes: 'Laporan diterima oleh teknisi',
        });

        return {
            status: 'success',
            message: 'Laporan diterima',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
        }),
    })

    // Begin work (On-site)
    .post('/reports/:id/start-work', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        const updated = await db
            .update(reports)
            .set({
                status: 'diproses',
                handlingStartedAt: new Date(),
                updatedAt: new Date(),
            })
            .where(eq(reports.id, reportId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: staffId,
            action: 'handling',
            fromStatus: 'penanganan',
            toStatus: 'diproses',
            notes: 'Teknisi mulai mengerjakan perbaikan di lokasi',
        });

        return {
            status: 'success',
            message: 'Pengerjaan dimulai',
            data: updated[0],
        };
    }, {
        body: t.Object({
            staffId: t.Number(),
        }),
    })

    // Complete a report (with proof photo)
    .post('/reports/:id/complete', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

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

        if (updated.length === 0) {
            return { status: 'error', message: 'Laporan tidak ditemukan' };
        }

        await db.insert(reportLogs).values({
            reportId,
            actorType: 'staff',
            actorId: staffId,
            action: 'completed',
            fromStatus: 'diproses',
            toStatus: 'selesai',
            notes: body.notes || 'Penanganan selesai',
            mediaUrls: body.mediaUrls || [],
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
            mediaUrls: t.Array(t.String()), // Required proof
        }),
    })

    // Get single report detail for technician
    .get('/reports/detail/:id', async ({ params }) => {
        const reportId = parseInt(params.id);

        const reportDetail = await db
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
                assignedAt: reports.assignedAt,
                handlingStartedAt: reports.handlingStartedAt,
                handlingCompletedAt: reports.handlingCompletedAt,
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

        const logs = await db
            .select()
            .from(reportLogs)
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
