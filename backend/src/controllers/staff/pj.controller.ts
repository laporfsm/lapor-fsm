import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte, inArray } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';
import { jwt } from '@elysiajs/jwt';
import PDFDocument from 'pdfkit';

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
            return { managedBuilding: undefined };
        }
        
        try {
            console.log(`DEBUG: Looking up Staff ID ${userId} for managedBuilding...`);
            const user = await db.select({ managedBuilding: staff.managedBuilding })
                .from(staff)
                .where(eq(staff.id, userId))
                .limit(1);
            
            console.log('DEBUG: DB Result:', user);
            return { managedBuilding: user[0]?.managedBuilding };
        } catch (e) {
            console.error('DEBUG: DB Lookup failed:', e);
            return { managedBuilding: undefined };
        }
    })
    // Dashboard statistics for PJ Gedung
    // Dashboard statistics for PJ Gedung
    .get('/dashboard', async ({ managedBuilding }) => {
        if (!managedBuilding) {
            return {
                status: 'error',
                message: 'Akses ditolak: Anda belum ditugaskan ke gedung manapun atau token tidak valid.'
            };
        }

        // Strict Filter: Reports.building == Staff.managed_building
        const whereClause = sql`${reports.building} = ${managedBuilding}`;

        // Uses Database Timezone/Logic for consistency
        const todayReports = await db.select({ count: count() })
            .from(reports)
            .where(and(sql`DATE(${reports.createdAt}) = CURRENT_DATE`, whereClause));
        
        const weekReports = await db.select({ count: count() })
            .from(reports)
            .where(and(sql`${reports.createdAt} >= NOW() - INTERVAL '7 days'`, whereClause));
        
        const monthReports = await db.select({ count: count() })
            .from(reports)
            .where(and(sql`${reports.createdAt} >= DATE_TRUNC('month', NOW())`, whereClause));

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

    // Get reports for PJ Gedung (focused on their building if filter provided)
    .get('/reports', async ({ query, managedBuilding }) => {
        const { status, building, isEmergency, startDate, endDate, search, period } = query;
        let conditions = [];

        if (!managedBuilding) {
            return { 
                status: 'error', 
                message: 'Akses ditolak: Akun Anda tidak memiliki wilayah gedung yang ditetapkan.' 
            };
        }

        // Apply strict scope filter: building column = managed_building from staff
        conditions.push(sql`${reports.building} = ${managedBuilding}`);

        // Optional sub-filtering (e.g. searching for room number inside the building)
        if (building) {
             conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
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
            sql`${reports.locationDetail} ILIKE ${'%' + search + '%'}`, // Search locationDetail instead of building since building is fixed
            sql`${categories.name} ILIKE ${'%' + search + '%'}`
        ));

        // Date Filtering Logic (SQL-based)
        if (period === 'today') {
            conditions.push(sql`DATE(${reports.createdAt}) = CURRENT_DATE`);
        } else if (period === 'week') {
            conditions.push(sql`${reports.createdAt} >= NOW() - INTERVAL '7 days'`);
        } else if (period === 'month') {
            conditions.push(sql`${reports.createdAt} >= DATE_TRUNC('month', NOW())`);
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

        if (!staffId || isNaN(staffId)) {
            return { status: 'error', message: 'Staff ID tidak valid' };
        }

        const foundStaff = await db.select().from(staff).where(eq(staff.id, staffId)).limit(1);

        if (foundStaff.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
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
            actorName: foundStaff[0]?.name || "PJ Gedung",
            actorRole: foundStaff[0]?.role || "pj_gedung",
            action: 'rejected',
            fromStatus: 'pending',
            toStatus: 'ditolak',
            reason: body.reason,
        });

        return { status: 'success', data: mapToMobileReport(updated[0]) };
    }, {
        body: t.Object({ staffId: t.Number(), reason: t.String() })
    })

    // Get statistics for PJ Gedung (Dynamic & Correctly Filtered)
    .get('/statistics', async ({ query, managedBuilding }) => {
        const { building } = query;
        
        let buildingFilter = managedBuilding || building;
        if (!buildingFilter) {
            return { status: 'error', message: 'Membutuhkan filter gedung' };
        }
        
        // Strict Match if managing, otherwise loose match for admin/general
        let whereClause = managedBuilding 
            ? sql`${reports.building} = ${managedBuilding}` 
            : sql`${reports.building} ILIKE ${buildingFilter}`;

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
    .get('/reports/export/pdf', async ({ query, set, managedBuilding }) => {
        const { status, building, isEmergency, startDate, endDate, search } = query;
        let conditions = [];

        // Enforce building filtering from JWT if available
        if (managedBuilding) {
             conditions.push(sql`${reports.building} = ${managedBuilding}`);
        } else if (building) {
            conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
        }
        if (status) {
            const statusList = (status as string).split(',');
            if (statusList.length > 1) {
                conditions.push(inArray(reports.status, statusList as any));
            } else {
                conditions.push(eq(reports.status, status as string));
            }
        }
        if (building && !managedBuilding) conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`); // Only add manual building filter if not scoped
        
        if (isEmergency === 'true') conditions.push(eq(reports.isEmergency, true));
        if (search) conditions.push(or(
            sql`${reports.title} ILIKE ${'%' + search + '%'}`,
            sql`${reports.building} ILIKE ${'%' + search + '%'}`,
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
                building: reports.building,
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
        doc.text(`Gedung Utama (Tanggung Jawab): ${managedBuilding || 'Semua'}`);

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
        doc.text('Gedung', 255, tableTop);
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
                doc.text('Gedung', 255, newPageY);
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
            doc.text(r.building || '-', 255, currentY, { width: 55, height: 12, ellipsis: true });
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
