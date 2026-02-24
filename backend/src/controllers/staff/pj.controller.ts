import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte, inArray } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';
import { logEventEmitter, LOG_EVENTS } from '../../utils/events';
import { jwt } from '@elysiajs/jwt';
import PDFDocument from 'pdfkit';
import { getStartOfWeek, getStartOfMonth } from '../../utils/date.utils';

const statusLabels: Record<string, string> = {
    'pending': 'Perlu Verifikasi',
    'terverifikasi': 'Terverifikasi',
    'ditolak': 'Ditolak'
};

export const pjController = new Elysia({ prefix: '/pj-gedung' })
    .use(
        jwt({
            name: 'jwt',
            secret: process.env.JWT_SECRET || 'lapor-fsm-secret-key-change-in-production'
        })
    )
    .derive(async ({ jwt, headers }) => {
        const auth = headers['authorization'];
        if (auth?.startsWith('Bearer ')) {
            const token = auth.slice(7);
            const payload = await jwt.verify(token);
            // console.log('DEBUG: Token Payload:', payload);
            if (payload) {
                return {
                    userId: payload.id as number,
                    userRole: payload.role as string
                };
            }
        }
        return { userId: undefined, userRole: undefined };
    })
    // Middleware to fetch fresh managed building from DB
    .derive(async ({ userId }) => {
        if (!userId) {
            console.log('DEBUG: No userId found in token');
            return { managedLocation: undefined };
        }

        try {
            console.log(`DEBUG: Looking up Staff ID ${userId} for managedLocation...`);
            const user = await db.select({ managedLocation: staff.managedLocation })
                .from(staff)
                .where(eq(staff.id, userId))
                .limit(1);

            console.log('DEBUG: DB Result:', user);
            return { managedLocation: user[0]?.managedLocation };
        } catch (e) {
            console.error('DEBUG: DB Lookup failed:', e);
            return { managedLocation: undefined };
        }
    })
    // Dashboard statistics for PJ Gedung
    .get('/dashboard', async ({ managedLocation }) => {
        if (!managedLocation) {
            return {
                status: 'error',
                message: 'Akses ditolak: Anda belum ditugaskan ke lokasi manapun atau token tidak valid.'
            };
        }

        const startOfWeek = getStartOfWeek();

        // Strict Filter: Reports.location == Staff.managed_location
        const whereClause = eq(reports.location, managedLocation);

        // Uses Database Timezone/Logic for consistency
        const todayReports = await db.select({ count: count() })
            .from(reports)
            .where(and(sql`DATE(${reports.createdAt}) = CURRENT_DATE`, whereClause));

        const weekReports = await db.select({ count: count() })
            .from(reports)
            .where(and(gte(reports.createdAt, startOfWeek), whereClause));

        const monthReports = await db.select({ count: count() })
            .from(reports)
            .where(and(gte(reports.createdAt, getStartOfMonth()), whereClause));

        const statusCounts = await db
            .select({
                status: reports.status,
                count: count(),
            })
            .from(reports)
            .where(whereClause)
            .groupBy(reports.status);

        const countsMap = statusCounts.reduce((acc, curr) => {
            acc[curr.status || 'unknown'] = curr.count;
            return acc;
        }, {} as Record<string, number>);

        return {
            status: 'success',
            data: {
                todayReports: Number(todayReports[0]?.count || 0),
                weekReports: Number(weekReports[0]?.count || 0),
                monthReports: Number(monthReports[0]?.count || 0),
                pending: Number(countsMap['pending'] || 0),
                verified: Number(countsMap['terverifikasi'] || 0),
                rejected: Number(countsMap['ditolak'] || 0),
            },
        };
    })

    // Get reports for PJ Lokasi (focused on their location if filter provided)
    .get('/reports', async ({ query, managedLocation }) => {
        const { status, location, isEmergency, startDate, endDate, search, period } = query;
        let conditions = [];

        if (!managedLocation) {
            return {
                status: 'error',
                message: 'Akses ditolak: Akun Anda tidak memiliki wilayah lokasi yang ditetapkan.'
            };
        }

        // Apply strict scope filter: location column = managedLocation from staff
        conditions.push(eq(reports.location, managedLocation));

        // Optional sub-filtering (e.g. searching for room number inside the location)
        if (location) {
            conditions.push(sql`${reports.location} ILIKE ${'%' + location + '%'}`);
        }

        // Support multiple statuses separated by comma (e.g., 'pending,terverifikasi')
        if (status) {
            const statusList = (status as string).split(',').map(s => s.trim());
            if (statusList.length > 1) {
                conditions.push(inArray(reports.status, statusList as any));
            } else {
                conditions.push(eq(reports.status, statusList[0]));
            }
        }

        if (isEmergency === 'true') conditions.push(eq(reports.isEmergency, true));
        if (search) conditions.push(or(
            sql`${reports.title} ILIKE ${'%' + search + '%'}`,
            sql`${reports.locationDetail} ILIKE ${'%' + search + '%'}`, // Search locationDetail instead of location since location is fixed
            sql`${categories.name} ILIKE ${'%' + search + '%'}`
        ));

        // Date Filtering Logic (Drizzle-operator based for better type support with Date objects)
        if (period === 'today') {
            conditions.push(sql`DATE(${reports.createdAt}) = CURRENT_DATE`);
        } else if (period === 'week') {
            conditions.push(gte(reports.createdAt, getStartOfWeek()));
        } else if (period === 'month') {
            conditions.push(gte(reports.createdAt, getStartOfMonth()));
        }

        // Explicit Date Range (if provided override or add to period)
        if (startDate) conditions.push(gte(reports.createdAt, new Date(startDate as string)));
        if (endDate) {
            const end = new Date(endDate as string);
            end.setHours(23, 59, 59, 999);
            conditions.push(lte(reports.createdAt, end));
        }

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                description: reports.description,
                location: reports.location,
                locationDetail: reports.locationDetail,
                status: reports.status,
                isEmergency: reports.isEmergency,
                createdAt: reports.createdAt,
                reporterName: users.name,
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

        if (!staffId || isNaN(staffId)) {
            return { status: 'error', message: 'Staff ID tidak valid' };
        }

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        if (foundStaff.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
        }

        const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (current.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        if (current[0].isEmergency) {
            return { status: 'error', message: 'Laporan darurat hanya bisa diverifikasi oleh Supervisor.' };
        }

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
            actorName: foundStaff[0]?.name || "PJ Lokasi",
            actorRole: foundStaff[0]?.role || "pj_gedung",
            action: 'verified',
            fromStatus: 'pending',
            toStatus: 'terverifikasi',
            reason: body.notes || 'Laporan telah diverifikasi oleh PJ Lokasi',
        });

        logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

        // Notify User
        if (updated[0].userId) {
            await NotificationService.notifyUser(updated[0].userId, 'Laporan Diverifikasi', `Laporan "${updated[0].title}" telah diverifikasi oleh PJ Lokasi.`);
        }

        // Notify Supervisor
        await NotificationService.notifyRole('supervisor', 'Laporan Terverifikasi', `Laporan baru di ${updated[0].location} telah diverifikasi oleh PJ Lokasi.`);

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

    // Reject report (pending -> ditolak)
    .post('/reports/:id/reject', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const staffId = body.staffId;

        if (!staffId || isNaN(staffId)) {
            return { status: 'error', message: 'Staff ID tidak valid' };
        }

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        if (foundStaff.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
        }

        const current = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (current.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        if (current[0].isEmergency) {
            return { status: 'error', message: 'Laporan darurat hanya bisa ditolak oleh Supervisor.' };
        }

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
            actorName: foundStaff[0]?.name || "PJ Lokasi",
            actorRole: foundStaff[0]?.role || "pj_gedung",
            action: 'rejected',
            fromStatus: 'pending',
            toStatus: 'ditolak',
            reason: body.reason,
        });

        logEventEmitter.emit(LOG_EVENTS.NEW_LOG, reportId);

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    })

    // Get statistics for PJ Lokasi (Dynamic & Correctly Filtered)
    .get('/statistics', async ({ query, managedLocation }) => {
        const { location } = query;

        let locationFilter = managedLocation || location;
        if (!locationFilter) {
            return { status: 'error', message: 'Membutuhkan filter lokasi' };
        }

        // Strict Match if managing, otherwise loose match for admin/general
        let whereClause = managedLocation
            ? eq(reports.location, managedLocation)
            : sql`${reports.location} ILIKE ${locationFilter}`;

        // 1. Issue Categories
        const categoryStats = await db.select({
            name: categories.name,
            count: count()
        })
            .from(reports)
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(whereClause)
            .groupBy(categories.name);

        // 2. Weekly Trend (last 7 days) - utilizing DB for date grouping
        // Retrieve counts for the last 7 days from the DB based on YYYY-MM-DD
        const weeklyRaw = await db.select({
            dateStr: sql<string>`TO_CHAR(${reports.createdAt}, 'YYYY-MM-DD')`,
            count: count()
        })
            .from(reports)
            .where(and(
                whereClause,
                sql`${reports.createdAt} >= CURRENT_DATE - INTERVAL '6 days'` // Last 7 days including today
            ))
            .groupBy(sql`TO_CHAR(${reports.createdAt}, 'YYYY-MM-DD')`)
            .orderBy(sql`TO_CHAR(${reports.createdAt}, 'YYYY-MM-DD')`);

        // Transform into full 7-day array
        const weeklyMap = weeklyRaw.reduce((acc, curr) => {
            acc[curr.dateStr] = Number(curr.count);
            return acc;
        }, {} as Record<string, number>);

        const fullWeeklyTrend = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const yyyy = d.getFullYear();
            const mm = String(d.getMonth() + 1).padStart(2, '0');
            const dd = String(d.getDate()).padStart(2, '0');
            const dateStr = `${yyyy}-${mm}-${dd}`;

            fullWeeklyTrend.push({
                day: d.toLocaleDateString('id-ID', { weekday: 'short' }),
                value: weeklyMap[dateStr] || 0
            });
        }

        // 3. Comparison (This Month vs Last Month) DOING IT IN SQL
        const thisMonthCount = await db.select({ count: count() })
            .from(reports)
            .where(and(
                whereClause,
                sql`DATE_TRUNC('month', ${reports.createdAt}) = DATE_TRUNC('month', CURRENT_DATE)`
            ));

        const lastMonthCount = await db.select({ count: count() })
            .from(reports)
            .where(and(
                whereClause,
                sql`DATE_TRUNC('month', ${reports.createdAt}) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')`
            ));

        // 4. Monthly Progress (Distribution within the current month)
        const monthlyProgressRaw = await db.select({
            week1: sql<number>`SUM(CASE WHEN EXTRACT(DAY FROM ${reports.createdAt}) BETWEEN 1 AND 7 THEN 1 ELSE 0 END)`,
            week2: sql<number>`SUM(CASE WHEN EXTRACT(DAY FROM ${reports.createdAt}) BETWEEN 8 AND 14 THEN 1 ELSE 0 END)`,
            week3: sql<number>`SUM(CASE WHEN EXTRACT(DAY FROM ${reports.createdAt}) BETWEEN 15 AND 21 THEN 1 ELSE 0 END)`,
            week4: sql<number>`SUM(CASE WHEN EXTRACT(DAY FROM ${reports.createdAt}) >= 22 THEN 1 ELSE 0 END)`,
        })
            .from(reports)
            .where(and(
                whereClause,
                sql`DATE_TRUNC('month', ${reports.createdAt}) = DATE_TRUNC('month', CURRENT_DATE)`
            ));

        const mp = monthlyProgressRaw[0];

        return {
            status: 'success',
            data: {
                categories: categoryStats.map(c => ({
                    label: c.name || 'Lainnya',
                    count: Number(c.count)
                })),
                weeklyTrend: fullWeeklyTrend,
                thisMonth: Number(thisMonthCount[0]?.count || 0),
                lastMonth: Number(lastMonthCount[0]?.count || 0),
                monthlyProgress: [
                    Number(mp?.week1 || 0),
                    Number(mp?.week2 || 0),
                    Number(mp?.week3 || 0),
                    Number(mp?.week4 || 0),
                ]
            }
        };
    })

    // Export PDF
    .get('/reports/export/pdf', async ({ query, set, managedLocation }) => {
        const { status, location, isEmergency, startDate, endDate, search } = query;
        let conditions = [];

        // Enforce location filtering from JWT if available
        if (managedLocation) {
            conditions.push(eq(reports.location, managedLocation));
        } else if (location) {
            conditions.push(sql`${reports.location} ILIKE ${'%' + location + '%'}`);
        }
        if (status) {
            const statusList = (status as string).split(',');
            if (statusList.length > 1) {
                conditions.push(inArray(reports.status, statusList as any));
            } else {
                conditions.push(eq(reports.status, status as string));
            }
        }
        if (location && !managedLocation) conditions.push(sql`${reports.location} ILIKE ${'%' + location + '%'}`); // Only add manual location filter if not scoped

        if (isEmergency === 'true') conditions.push(eq(reports.isEmergency, true));
        if (search) conditions.push(or(
            sql`${reports.title} ILIKE ${'%' + search + '%'}`,
            sql`${reports.location} ILIKE ${'%' + search + '%'}`,
            sql`${categories.name} ILIKE ${'%' + search + '%'}`
        ));

        if (startDate) conditions.push(gte(reports.createdAt, new Date(startDate as string)));
        if (endDate) {
            const end = new Date(endDate as string);
            end.setHours(23, 59, 59, 999);
            conditions.push(lte(reports.createdAt, end));
        }

        const whereClause = conditions.length > 0 ? and(...conditions) : undefined;


        const result = await db
            .select({
                id: reports.id,
                title: reports.title,
                location: reports.location,
                locationDetail: reports.locationDetail,
                isEmergency: reports.isEmergency,
                status: reports.status,
                createdAt: reports.createdAt,
                reporterName: users.name,
                categoryName: categories.name,
            })
            .from(reports)
            .leftJoin(users, eq(reports.userId, users.id))
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .where(whereClause)
            .orderBy(desc(reports.createdAt));

        // Generate PDF
        const doc = new PDFDocument({ margin: 40, size: 'A4' });
        const chunks: Buffer[] = [];

        doc.on('data', (chunk: Buffer) => chunks.push(chunk));

        // Header
        doc.fontSize(20).text('LAPORAN RIWAYAT VERIFIKASI', { align: 'center' });
        doc.fontSize(12).text('Lapor FSM - Sistem Informasi Pelayanan Fasilitas', { align: 'center' });
        doc.moveDown();
        doc.moveTo(40, doc.y).lineTo(555, doc.y).stroke();
        doc.moveDown();

        // Metadata
        doc.fontSize(10).font('Helvetica');
        doc.text(`Dicetak pada: ${new Date().toLocaleString('id-ID', { dateStyle: 'long', timeStyle: 'short' })}`);
        doc.text(`Lokasi Utama (Tanggung Jawab): ${managedLocation || 'Semua'}`);

        const friendlyStatus = status ?
            (status as string).split(',').map(s => statusLabels[s] || s).join(', ') :
            'Semua';
        doc.text(`Filter Status: ${friendlyStatus}`);

        if (startDate || endDate) {
            const start = startDate ? new Date(startDate as string).toLocaleDateString('id-ID') : '-';
            const end = endDate ? new Date(endDate as string).toLocaleDateString('id-ID') : '-';
            doc.text(`Periode: ${start} s/d ${end}`);
        }
        doc.moveDown(2);

        // Table Header Styling
        const tableTop = doc.y;
        doc.rect(40, tableTop - 5, 515, 20).fill('#059669'); // Emerald background

        doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(8);
        doc.text('No', 40, tableTop);
        doc.text('Tanggal', 60, tableTop);
        doc.text('Judul Laporan', 105, tableTop);
        doc.text('Kategori', 195, tableTop);
        doc.text('Lokasi', 255, tableTop);
        doc.text('Lokasi', 315, tableTop);
        doc.text('Pelapor', 385, tableTop);
        doc.text('Status', 455, tableTop);
        doc.text('Darurat', 515, tableTop);

        doc.fillColor('#000000').font('Helvetica'); // Reset
        doc.moveDown(1.5);

        // Rows
        result.forEach((r, i) => {
            if (doc.y > 750) {
                doc.addPage();
                const newPageY = doc.y;
                doc.rect(40, newPageY - 5, 515, 20).fill('#059669');
                doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(8);
                doc.text('No', 40, newPageY);
                doc.text('Tanggal', 60, newPageY);
                doc.text('Judul Laporan', 105, newPageY);
                doc.text('Kategori', 195, newPageY);
                doc.text('Lokasi', 255, newPageY);
                doc.text('Lokasi', 315, newPageY);
                doc.text('Pelapor', 385, newPageY);
                doc.text('Status', 455, newPageY);
                doc.text('Darurat', 515, newPageY);
                doc.fillColor('#000000').font('Helvetica');
                doc.moveDown(1.5);
            }

            const currentY = doc.y;
            const formattedDate = new Date(r.createdAt!).toLocaleDateString('id-ID', { day: '2-digit', month: '2-digit', year: '2-digit' });

            // Draw horizontal line
            doc.moveTo(40, currentY - 5).lineTo(555, currentY - 5).strokeColor('#E2E8F0').lineWidth(0.5).stroke();

            doc.fontSize(7).fillColor('#1E293B');
            doc.text((i + 1).toString(), 40, currentY, { width: 15 });
            doc.text(formattedDate, 60, currentY, { width: 40 });
            doc.text(r.title || '-', 105, currentY, { width: 85, height: 12, ellipsis: true });
            doc.text(r.categoryName || '-', 195, currentY, { width: 55, height: 12, ellipsis: true });
            doc.text(r.location || '-', 255, currentY, { width: 55, height: 12, ellipsis: true });
            doc.text(r.locationDetail || '-', 315, currentY, { width: 65, height: 12, ellipsis: true });
            doc.text(r.reporterName || '-', 385, currentY, { width: 65, height: 12, ellipsis: true });

            const sLabel = statusLabels[r.status!] || r.status;
            doc.text(sLabel || '-', 455, currentY, { width: 55 });
            doc.text(r.isEmergency ? 'YA' : 'TIDAK', 515, currentY, { width: 40 });

            doc.moveDown(1.5);
        });

        doc.end();

        // Wait for PDF to finish
        const pdfBuffer = await new Promise<Buffer>((resolve) => {
            doc.on('end', () => resolve(Buffer.concat(chunks)));
        });

        const timestamp = new Date().toISOString().replace(/[:T]/g, '_').split('.')[0];
        set.headers['Content-Type'] = 'application/pdf';
        set.headers['Content-Disposition'] = `attachment; filename=Laporan_Riwayat_Verifikasi_${timestamp}.pdf`;

        return pdfBuffer;

    });
