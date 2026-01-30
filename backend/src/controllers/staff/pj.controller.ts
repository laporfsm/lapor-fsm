import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reports, reportLogs, staff, users, categories } from '../../db/schema';
import { eq, desc, and, or, sql, count, gte, lte, inArray } from 'drizzle-orm';
import { mapToMobileReport } from '../../utils/mapper';
import { NotificationService } from '../../services/notification.service';
import PDFDocument from 'pdfkit';

const statusLabels: Record<string, string> = {
    'pending': 'Perlu Verifikasi',
    'terverifikasi': 'Terverifikasi',
    'ditolak': 'Ditolak'
};

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
        const { status, building, isEmergency, startDate, endDate, search } = query;
        let conditions = [];
        if (status) {
            const statusList = (status as string).split(',');
            if (statusList.length > 1) {
                conditions.push(inArray(reports.status, statusList as any));
            } else {
                conditions.push(eq(reports.status, status as string));
            }
        }
        if (building) conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
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
    })

    // Get statistics for PJ Gedung
    .get('/statistics', async ({ query }) => {
        const { building } = query;
        let whereClause = building ? sql`${reports.building} ILIKE ${'%' + building + '%'}` : undefined;

        // 1. Issue Categories
        const categoryStats = await db.select({
            name: categories.name,
            count: count()
        })
        .from(reports)
        .leftJoin(categories, eq(reports.categoryId, categories.id))
        .where(whereClause)
        .groupBy(categories.name);

        // 2. Weekly Trend (last 7 days)
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        const weeklyTrend = await db.select({
            date: sql`DATE(${reports.createdAt})`,
            count: count()
        })
        .from(reports)
        .where(and(whereClause, gte(reports.createdAt, sevenDaysAgo)))
        .groupBy(sql`DATE(${reports.createdAt})`)
        .orderBy(sql`DATE(${reports.createdAt})`);

        // 3. Comparison (This Month vs Last Month)
        const startOfThisMonth = new Date();
        startOfThisMonth.setDate(1);
        startOfThisMonth.setHours(0, 0, 0, 0);

        const startOfLastMonth = new Date(startOfThisMonth);
        startOfLastMonth.setMonth(startOfLastMonth.getMonth() - 1);

        const thisMonthCount = await db.select({ count: count() }).from(reports).where(and(whereClause, gte(reports.createdAt, startOfThisMonth)));
        const lastMonthCount = await db.select({ count: count() }).from(reports).where(and(whereClause, and(gte(reports.createdAt, startOfLastMonth), lte(reports.createdAt, startOfThisMonth))));

        return {
            status: 'success',
            data: {
                categories: categoryStats.map(c => ({
                    label: c.name || 'Lainnya',
                    count: Number(c.count)
                })),
                weeklyTrend: weeklyTrend.map(t => ({
                    day: new Date(t.date as string).toLocaleDateString('id-ID', { weekday: 'short' }),
                    value: Number(t.count)
                })),
                thisMonth: Number(thisMonthCount[0].count),
                lastMonth: Number(lastMonthCount[0].count),
            }
        };
    })

    // Export PDF
    .get('/reports/export/pdf', async ({ query, set }) => {
        const { status, building, isEmergency, startDate, endDate, search } = query;
        let conditions = [];
        if (status) {
            const statusList = (status as string).split(',');
            if (statusList.length > 1) {
                conditions.push(inArray(reports.status, statusList as any));
            } else {
                conditions.push(eq(reports.status, status as string));
            }
        }
        if (building) conditions.push(sql`${reports.building} ILIKE ${'%' + building + '%'}`);
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
        
        doc.on('data', (chunk) => chunks.push(chunk));
        
        // Header
        doc.fontSize(20).text('LAPORAN RIWAYAT VERIFIKASI', { align: 'center' });
        doc.fontSize(12).text('Lapor FSM - Sistem Informasi Pelayanan Fasilitas', { align: 'center' });
        doc.moveDown();
        doc.moveTo(40, doc.y).lineTo(555, doc.y).stroke();
        doc.moveDown();

        // Metadata
        doc.fontSize(10).font('Helvetica');
        doc.text(`Dicetak pada: ${new Date().toLocaleString('id-ID', { dateStyle: 'long', timeStyle: 'short' })}`);
        doc.text(`Filter Gedung: ${building || 'Semua'}`);
        
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
