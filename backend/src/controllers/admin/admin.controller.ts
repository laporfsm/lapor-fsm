import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { staff, users, categories, reports, reportLogs } from '../../db/schema';
import { eq, desc, count, sql, and, or, not, gte, inArray } from 'drizzle-orm';
import { NotificationService } from '../../services/notification.service';
import { mapToMobileUser, mapToMobileReport } from '../../utils/mapper';
import PDFDocument from 'pdfkit';
import ExcelJS from 'exceljs';

export const adminController = new Elysia({ prefix: '/admin' })
    // ==========================================
    // STAFF MANAGEMENT
    // ==========================================

    // Get all staff
    .get('/staff', async () => {
        const staffList = await db
            .select({
                id: staff.id,
                name: staff.name,
                email: staff.email,
                phone: staff.phone,
                role: staff.role,
                specialization: staff.specialization,
                isActive: staff.isActive,
                managedLocation: staff.managedLocation,
                createdAt: staff.createdAt,
            })
            .from(staff)
            .orderBy(desc(staff.createdAt));

        return {
            status: 'success',
            data: staffList.map(s => mapToMobileUser(s)),
        };
    })

    // Create new staff
    .post('/staff', async ({ body }) => {
        const existing = await db
            .select()
            .from(staff)
            .where(eq(staff.email, body.email))
            .limit(1);

        if (existing.length > 0) {
            return { status: 'error', message: 'Email sudah terdaftar' };
        }

        const hashedPassword = await Bun.password.hash(body.password);

        const newStaff = await db.insert(staff).values({
            name: body.name,
            email: body.email,
            phone: body.phone,
            password: hashedPassword,
            role: body.role,
            specialization: body.specialization,
            managedLocation: body.managedLocation,
            isActive: true,
        }).returning();

        return {
            status: 'success',
            message: 'Staff berhasil ditambahkan',
            data: {
                id: newStaff[0].id,
                name: newStaff[0].name,
                email: newStaff[0].email,
                role: newStaff[0].role,
            },
        };
    }, {
        body: t.Object({
            name: t.String(),
            email: t.String(),
            phone: t.Optional(t.String()),
            password: t.String(),
            role: t.String(), // 'teknisi', 'supervisor', 'admin', 'pj_gedung'
            specialization: t.Optional(t.String()),
            managedLocation: t.Optional(t.String()),
        }),
    })

    // Update staff
    .put('/staff/:id', async ({ params, body }) => {
        const staffId = parseInt(params.id);

        // If email is being updated, check if it's already taken
        if (body.email) {
            const existing = await db
                .select()
                .from(staff)
                .where(and(eq(staff.email, body.email), not(eq(staff.id, staffId))))
                .limit(1);

            if (existing.length > 0) {
                return { status: 'error', message: 'Email sudah digunakan oleh staff lain' };
            }
        }

        const updateData: any = { ...body };

        if (body.password) {
            updateData.password = await Bun.password.hash(body.password);
        }

        const updated = await db
            .update(staff)
            .set(updateData)
            .where(eq(staff.id, staffId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
        }

        return {
            status: 'success',
            message: 'Staff berhasil diupdate',
            data: {
                id: updated[0].id,
                name: updated[0].name,
                email: updated[0].email,
                role: updated[0].role,
                isActive: updated[0].isActive,
            },
        };
    }, {
        body: t.Object({
            name: t.Optional(t.String()),
            email: t.Optional(t.String()),
            phone: t.Optional(t.String()),
            role: t.Optional(t.String()),
            specialization: t.Optional(t.String()),
            isActive: t.Optional(t.Boolean()),
            password: t.Optional(t.String()),
            managedLocation: t.Optional(t.String()),
        }),
    })

    // Delete/Deactivate staff
    .delete('/staff/:id', async ({ params }) => {
        const updated = await db
            .update(staff)
            .set({ isActive: false })
            .where(eq(staff.id, parseInt(params.id)))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Staff tidak ditemukan' };
        return { status: 'success', message: 'Staff berhasil dinonaktifkan' };
    })

    // ==========================================
    // CATEGORY MANAGEMENT
    // ==========================================

    .post('/categories', async ({ body }) => {
        const newCategory = await db.insert(categories).values({
            name: body.name,
            type: body.type,
            icon: body.icon,
            description: body.description,
        }).returning();

        return { status: 'success', data: newCategory[0] };
    }, {
        body: t.Object({
            name: t.String(),
            type: t.String(),
            icon: t.Optional(t.String()),
            description: t.Optional(t.String()),
        }),
    })

    // ==========================================
    // DASHBOARD ANALYTICS
    // ==========================================

    .get('/dashboard', async () => {
        const totalReports = await db.select({ count: count() }).from(reports);
        const reportsByStatus = await db.select({ status: reports.status, count: count() }).from(reports).groupBy(reports.status);
        const totalUsers = await db.select({ count: count() }).from(users);

        // Average handling time calculation
        const completedWithTime = await db
            .select({
                id: reports.id,
                handlingStartedAt: reports.handlingStartedAt,
                handlingCompletedAt: reports.handlingCompletedAt,
            })
            .from(reports)
            .where(eq(reports.status, 'selesai'))
            .limit(100);

        let avgHandlingMinutes = 0;
        const validReports = completedWithTime.filter(r => r.handlingStartedAt && r.handlingCompletedAt);
        if (validReports.length > 0) {
            const totalMinutes = validReports.reduce((sum, r) => {
                const diff = new Date(r.handlingCompletedAt!).getTime() - new Date(r.handlingStartedAt!).getTime();
                return sum + (diff / 60000);
            }, 0);
            avgHandlingMinutes = Math.round(totalMinutes / validReports.length);
        }

        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        // 3. Weekly Report Trend (7-day continuity fix)
        const weeklyTrendData = await db.select({
            date: sql`DATE(${reports.createdAt})`,
            count: count()
        })
            .from(reports)
            .where(gte(reports.createdAt, sevenDaysAgo))
            .groupBy(sql`DATE(${reports.createdAt})`)
            .orderBy(sql`DATE(${reports.createdAt})`);

        const trendMap = weeklyTrendData.reduce((acc, curr) => {
            acc[new Date(curr.date as string).toDateString()] = Number(curr.count);
            return acc;
        }, {} as Record<string, number>);

        const fullWeeklyTrend = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dateStr = d.toDateString();
            fullWeeklyTrend.push({
                day: d.toLocaleDateString('id-ID', { weekday: 'short' }),
                value: trendMap[dateStr] || 0
            });
        }

        const totalEmergency = await db.select({ count: count() }).from(reports).where(eq(reports.isEmergency, true));

        return {
            status: 'success',
            data: {
                totalReports: totalReports[0]?.count || 0,
                totalUsers: totalUsers[0]?.count || 0,
                totalEmergency: totalEmergency[0]?.count || 0,
                avgHandlingMinutes,
                reportsByStatus: reportsByStatus.reduce((acc, curr) => {
                    acc[curr.status || 'unknown'] = curr.count;
                    return acc;
                }, {} as Record<string, number>),
                weeklyTrend: fullWeeklyTrend,
            },
        };
    })

    // Fetch actual statistics for charts
    .get('/statistics', async () => {
        try {
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

            // 1. User Growth (last 30 days)
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

            const growthData = await db.select({
                date: sql`DATE(${users.createdAt})`,
                count: count()
            })
                .from(users)
                .where(gte(users.createdAt, thirtyDaysAgo))
                .groupBy(sql`DATE(${users.createdAt})`)
                .orderBy(sql`DATE(${users.createdAt})`);

            // 2. User Distribution by Role
            const roleDistributionStaff = await db.select({
                role: staff.role,
                count: count()
            })
                .from(staff)
                .groupBy(staff.role);

            const totalPelapor = await db.select({ count: count() }).from(users);

            const distribution: Record<string, number> = {
                'Pelapor': Number(totalPelapor[0]?.count || 0)
            };
            roleDistributionStaff.forEach(s => {
                if (s.role) {
                    const roleName = s.role.charAt(0).toUpperCase() + s.role.slice(1);
                    distribution[roleName] = Number(s.count);
                }
            });

            // 3. Report Volume by Category (Top 5)
            const reportVolume = await db.select({
                categoryName: categories.name,
                total: count(),
                done: sql`COUNT(CASE WHEN ${reports.status} = 'selesai' THEN 1 END)`
            })
                .from(reports)
                .leftJoin(categories, eq(reports.categoryId, categories.id))
                .groupBy(categories.name)
                .orderBy(desc(count()))
                .limit(5);

            // 4. Activity Traffic (Last 7 Days) - Includes user registrations, verifications, and report creations
            const trafficData = await db.select({
                date: sql`DATE(${reportLogs.timestamp})`,
                count: count()
            })
                .from(reportLogs)
                .where(and(
                    gte(reportLogs.timestamp, sevenDaysAgo),
                    or(
                        eq(reportLogs.action, 'register'),
                        eq(reportLogs.action, 'verify_email'),
                        eq(reportLogs.action, 'created')
                    )
                ))
                .groupBy(sql`DATE(${reportLogs.timestamp})`)
                .orderBy(sql`DATE(${reportLogs.timestamp})`);

            const trafficMap = trafficData.reduce((acc, curr) => {
                if (curr.date) {
                    acc[new Date(curr.date as any).toDateString()] = Number(curr.count);
                }
                return acc;
            }, {} as Record<string, number>);

            const fullTrafficTrend = [];
            for (let i = 6; i >= 0; i--) {
                const d = new Date();
                d.setDate(d.getDate() - i);
                const dateStr = d.toDateString();
                fullTrafficTrend.push({
                    day: d.toLocaleDateString('id-ID', { weekday: 'short' }),
                    value: trafficMap[dateStr] || 0
                });
            }

            return {
                status: 'success',
                data: {
                    userGrowth: growthData.map(g => {
                        const date = g.date ? new Date(g.date as any) : new Date();
                        return {
                            date: date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }),
                            value: Number(g.count)
                        };
                    }),
                    activeUsers: distribution['Pelapor'] || 0,
                    totalLogin: 42, // Placeholder
                    userDistribution: distribution,
                    reportVolume: reportVolume.map(rv => ({
                        dept: rv.categoryName || 'Lainnya',
                        in: Number(rv.total),
                        out: Number(rv.done)
                    })),
                    appUsage: fullTrafficTrend
                }
            };
        } catch (error) {
            console.error('Error in /statistics:', error);
            return {
                status: 'error',
                message: 'Gagal mengambil statistik',
                details: error instanceof Error ? error.message : String(error)
            };
        }
    })

    // Export Users PDF
    .get('/users/export/pdf', async ({ set }) => {
        try {
            const userList = await db.select().from(users).orderBy(desc(users.createdAt));
            const staffList = await db.select().from(staff).orderBy(desc(staff.createdAt));

            const doc = new PDFDocument({ margin: 30, size: 'A4', layout: 'landscape', bufferPages: true });
            const chunks: Buffer[] = [];

            // Promise wrapper to handle stream completion and errors
            const pdfBufferPromise = new Promise<Buffer>((resolve, reject) => {
                doc.on('data', (chunk) => chunks.push(chunk));
                doc.on('end', () => resolve(Buffer.concat(chunks)));
                doc.on('error', (err) => reject(err));
            });

            // Helper to sanitize text for standard PDF fonts (removes emojis/unsupported chars)
            const safeText = (str: string | null | undefined): string => {
                if (!str) return '-';
                return str.replace(/[^\x20-\x7E\xA0-\xFF\n\r\t]/g, '').trim() || '-';
            };

            // --- STYLING CONSTANTS ---
            const colors = {
                primary: '#7C3AED', // Admin Purple 600
                secondary: '#8B5CF6', // Admin Purple 500
                text: '#1F2937',
                textLight: '#6B7280',
                border: '#E5E7EB',
                rowOdd: '#F9FAFB',
                white: '#FFFFFF'
            };

            // --- HEADER ---
            doc.font('Helvetica-Bold').fontSize(24).fillColor(colors.primary).text('Lapor FSM!', 30, 30);
            doc.fontSize(10).fillColor(colors.textLight).text('Sistem Informasi Pelaporan Fasilitas FSM Undip', 30, 55);

            doc.fontSize(14).fillColor(colors.text).text('DATA PENGGUNA (USER & STAFF)', 400, 30, { align: 'right', width: 410 });
            doc.fontSize(9).fillColor(colors.textLight).text(`Dicetak: ${new Date().toLocaleString('id-ID')}`, 400, 50, { align: 'right', width: 410 });

            doc.moveTo(30, 75).lineTo(812, 75).lineWidth(1).stroke(colors.primary);

            // --- SUMMARY CARD ---
            const summaryY = 90;
            doc.roundedRect(30, summaryY, 782, 50, 5).fill(colors.rowOdd).stroke(colors.border);

            const drawSummaryItem = (label: string, value: string, x: number) => {
                doc.fillColor(colors.textLight).fontSize(9).text(safeText(label), x, summaryY + 10, { align: 'center', width: 150 });
                doc.fillColor(colors.primary).font('Helvetica-Bold').fontSize(14).text(safeText(value), x, summaryY + 25, { align: 'center', width: 150 });
            };

            drawSummaryItem('Total Pelapor', userList.length.toString(), 30);
            drawSummaryItem('Total Staff', staffList.length.toString(), 250);
            drawSummaryItem('Total Pengguna', (userList.length + staffList.length).toString(), 470);

            // --- TABLE HELPER ---
            let currentY = 160;

            const drawTableHeader = (headers: string[], colWidths: number[]) => {
                const rowHeight = 25;
                doc.rect(30, currentY, 782, rowHeight).fill(colors.primary);
                let currentX = 30;
                doc.fillColor(colors.white).font('Helvetica-Bold').fontSize(9);
                headers.forEach((header, i) => {
                    doc.text(safeText(header), currentX + 5, currentY + 7, { width: colWidths[i] - 10, align: 'left' });
                    currentX += colWidths[i];
                });
                currentY += rowHeight;
            };

            const drawTableRow = (data: string[], colWidths: number[], isOdd: boolean) => {
                const rowHeight = 25;
                // Page Break Check
                if (currentY + rowHeight > 550) {
                    doc.addPage({ margin: 30, size: 'A4', layout: 'landscape' });
                    currentY = 30;
                }

                if (isOdd) {
                    doc.rect(30, currentY, 782, rowHeight).fill(colors.rowOdd);
                }

                let currentX = 30;
                doc.fillColor(colors.text).font('Helvetica').fontSize(9);
                data.forEach((text, i) => {
                    doc.text(safeText(text), currentX + 5, currentY + 7, { width: colWidths[i] - 10, height: rowHeight - 10, lineBreak: false, ellipsis: true });
                    currentX += colWidths[i];
                });
                currentY += rowHeight;
            };

            // --- SECTION 1: PELAPOR ---
            doc.font('Helvetica-Bold').fontSize(12).fillColor(colors.text).text('1. DAFTAR PELAPOR (MAHASISWA/UMUM)', 30, 160);
            currentY = 180;

            const userCols = [30, 150, 180, 100, 150, 80, 92]; // Total 782
            const userHeaders = ['No', 'Nama', 'Email', 'NIM/NIP', 'Unit (Dept/Fakultas)', 'Status', 'Terdaftar'];

            drawTableHeader(userHeaders, userCols);

            userList.forEach((u, i) => {
                drawTableRow([
                    (i + 1).toString(),
                    u.name,
                    u.email,
                    u.nimNip || '-',
                    (u.department || u.faculty) ? `${u.department || ''} ${u.faculty || ''}` : '-',
                    u.isActive ? 'Aktif' : 'Nonaktif',
                    u.createdAt ? new Date(u.createdAt).toLocaleDateString('id-ID') : '-'
                ], userCols, i % 2 === 1);
            });

            // --- SECTION 2: STAFF ---
            currentY += 20;
            if (currentY + 50 > 550) {
                doc.addPage({ margin: 30, size: 'A4', layout: 'landscape' });
                currentY = 30;
            }

            doc.font('Helvetica-Bold').fontSize(12).fillColor(colors.text).text('2. DAFTAR STAFF (TEKNISI/PJ/SUPERVISOR)', 30, currentY);
            currentY += 20;

            const staffCols = [30, 150, 180, 100, 150, 80, 92];
            const staffHeaders = ['No', 'Nama', 'Email', 'Telepon', 'Role & Lokasi', 'Status', 'Bergabung'];

            drawTableHeader(staffHeaders, staffCols);

            staffList.forEach((s, i) => {
                const roleStr = s.role ? s.role.toUpperCase() : '-';
                const locStr = s.managedLocation || s.specialization || '';
                drawTableRow([
                    (i + 1).toString(),
                    s.name,
                    s.email,
                    s.phone || '-',
                    `${roleStr} ${locStr ? `(${locStr})` : ''}`,
                    s.isActive ? 'Aktif' : 'Nonaktif',
                    s.createdAt ? new Date(s.createdAt).toLocaleDateString('id-ID') : '-'
                ], staffCols, i % 2 === 1);
            });

            // --- FOOTER ---
            const range = doc.bufferedPageRange();
            for (let i = 0; i < range.count; i++) {
                doc.switchToPage(i);
                doc.fontSize(8).fillColor(colors.textLight).text(
                    `Halaman ${i + 1} dari ${range.count} - Lapor FSM Admin Export`,
                    30,
                    570,
                    { align: 'right', width: 782 }
                );
                doc.moveTo(30, 565).lineTo(812, 565).lineWidth(0.5).stroke(colors.border);
            }

            doc.end();
            const buffer = await pdfBufferPromise;

            set.headers['Content-Type'] = 'application/pdf';
            set.headers['Content-Disposition'] = 'attachment; filename=data_users_laporfsm.pdf';
            return buffer;
        } catch (e) {
            console.error('Error generating Users PDF:', e);
            set.status = 500;
            return { error: 'Failed to generate PDF', details: String(e) };
        }
    })

    // Export Users Excel
    .get('/users/export/excel', async ({ set }) => {
        try {
            const userList = await db.select().from(users).orderBy(desc(users.createdAt));
            const staffList = await db.select().from(staff).orderBy(desc(staff.createdAt));

            const workbook = new ExcelJS.Workbook();

            // Sheet for Pelapor
            const sheet1 = workbook.addWorksheet('Pelapor');
            sheet1.columns = [
                { header: 'Nama', key: 'name', width: 25 },
                { header: 'Email', key: 'email', width: 30 },
                { header: 'Telepon', key: 'phone', width: 15 },
                { header: 'NIM/NIP', key: 'nimNip', width: 15 },
                { header: 'Departemen', key: 'dept', width: 20 },
                { header: 'Fakultas', key: 'faculty', width: 20 },
                { header: 'Status Terverifikasi', key: 'is_verified', width: 15 },
                { header: 'Status Akun', key: 'is_active', width: 12 },
                { header: 'Tanggal Daftar', key: 'created_at', width: 20 },
            ];

            userList.forEach(u => {
                sheet1.addRow({
                    name: u.name,
                    email: u.email,
                    phone: u.phone,
                    nimNip: u.nimNip,
                    dept: u.department,
                    faculty: u.faculty,
                    is_verified: u.isVerified ? 'YA' : 'TIDAK',
                    is_active: u.isActive ? 'AKTIF' : 'NONAKTIF',
                    created_at: u.createdAt
                });
            });

            // Sheet for Staff
            const sheet2 = workbook.addWorksheet('Staff');
            sheet2.columns = [
                { header: 'Nama', key: 'name', width: 25 },
                { header: 'Email', key: 'email', width: 30 },
                { header: 'Telepon', key: 'phone', width: 15 },
                { header: 'Role', key: 'role', width: 15 },
                { header: 'Spesialisasi', key: 'specialization', width: 20 },
                { header: 'Gedung Dikelola', key: 'building', width: 20 },
                { header: 'Status', key: 'is_active', width: 12 },
                { header: 'Tanggal Gabung', key: 'created_at', width: 20 },
            ];

            staffList.forEach(s => {
                sheet2.addRow({
                    name: s.name,
                    email: s.email,
                    phone: s.phone,
                    role: s.role,
                    specialization: s.specialization,
                    building: s.managedLocation,
                    is_active: s.isActive ? 'AKTIF' : 'NONAKTIF',
                    created_at: s.createdAt
                });
            });

            const buffer = await workbook.xlsx.writeBuffer();
            set.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            set.headers['Content-Disposition'] = 'attachment; filename=data_users_laporfsm.xlsx';
            return buffer;
        } catch (e) {
            console.error('Error generating Users Excel:', e);
            set.status = 500;
            return { error: 'Failed to generate Excel', details: String(e) };
        }
    })

    // Export Reports PDF
    .get('/reports/export/pdf', async ({ set }) => {
        try {
            const reportList = await db
                .select({
                    id: reports.id,
                    title: reports.title,
                    status: reports.status,
                    building: reports.location,
                    isEmergency: reports.isEmergency,
                    createdAt: reports.createdAt,
                    reporterName: users.name,
                    categoryName: categories.name,
                    location: reports.locationDetail,
                })
                .from(reports)
                .leftJoin(users, eq(reports.userId, users.id))
                .leftJoin(categories, eq(reports.categoryId, categories.id))
                .orderBy(desc(reports.createdAt));

            const doc = new PDFDocument({ margin: 30, size: 'A4', layout: 'landscape', bufferPages: true });
            const chunks: Buffer[] = [];

            // Promise wrapper to handle stream completion and errors
            const pdfBufferPromise = new Promise<Buffer>((resolve, reject) => {
                doc.on('data', (chunk) => chunks.push(chunk));
                doc.on('end', () => resolve(Buffer.concat(chunks)));
                doc.on('error', (err) => reject(err));
            });

            // Helper to sanitize text for standard PDF fonts (removes emojis/unsupported chars)
            const safeText = (str: string | null | undefined): string => {
                if (!str) return '-';
                return str.replace(/[^\x20-\x7E\xA0-\xFF\n\r\t]/g, '').trim() || '-';
            };

            // --- STYLING CONSTANTS ---
            const colors = {
                primary: '#7C3AED', // Admin Purple 600
                text: '#1F2937',
                textLight: '#6B7280',
                border: '#E5E7EB',
                rowOdd: '#F9FAFB',
                white: '#FFFFFF',
                danger: '#EF4444',
                warning: '#F59E0B',
                success: '#10B981'
            };

            // --- HEADER ---
            doc.font('Helvetica-Bold').fontSize(24).fillColor(colors.primary).text('Lapor FSM!', 30, 30);
            doc.fontSize(10).fillColor(colors.textLight).text('Sistem Informasi Pelaporan Fasilitas FSM Undip', 30, 55);

            doc.fontSize(14).fillColor(colors.text).text('LAPORAN KERUSAKAN FASILITAS', 400, 30, { align: 'right', width: 410 });
            doc.fontSize(9).fillColor(colors.textLight).text(`Dicetak: ${new Date().toLocaleString('id-ID')}`, 400, 50, { align: 'right', width: 410 });

            doc.moveTo(30, 75).lineTo(812, 75).lineWidth(1).stroke(colors.primary);

            // --- SUMMARY STATISTICS ---
            const summaryY = 90;
            doc.roundedRect(30, summaryY, 782, 50, 5).fill(colors.rowOdd).stroke(colors.border);

            const total = reportList.length;
            const done = reportList.filter(r => r.status === 'selesai').length;
            const process = reportList.filter(r => ['proses', 'tunggu-sparepart', 'dijadwalkan'].includes(r.status || '')).length;
            const pending = reportList.filter(r => ['menunggu-konfirmasi', 'diterima', 'ditolak', 'belum_ditangani'].includes(r.status || '')).length;

            const drawSummaryItem = (label: string, value: string, x: number, color: string = colors.primary) => {
                doc.fillColor(colors.textLight).fontSize(9).text(safeText(label), x, summaryY + 10, { align: 'center', width: 120 });
                doc.fillColor(color).font('Helvetica-Bold').fontSize(14).text(safeText(value), x, summaryY + 25, { align: 'center', width: 120 });
            };

            drawSummaryItem('Total Laporan', total.toString(), 30);
            drawSummaryItem('Selesai', done.toString(), 200, colors.success);
            drawSummaryItem('Dalam Proses', process.toString(), 370, colors.warning);
            drawSummaryItem('Pending/Baru', pending.toString(), 540, colors.danger);

            // --- TABLE ---
            let currentY = 160;
            const colWidths = [40, 90, 180, 100, 120, 130, 80, 42]; // Total 782
            const headers = ['ID', 'Tanggal', 'Judul & Masalah', 'Kategori', 'Gedung/Lokasi', 'Pelapor', 'Status', 'Urgensi'];

            // Draw Header
            const drawHeader = () => {
                doc.rect(30, currentY, 782, 25).fill(colors.primary);
                let currentX = 30;
                doc.fillColor(colors.white).font('Helvetica-Bold').fontSize(9);
                headers.forEach((header, i) => {
                    doc.text(safeText(header), currentX + 5, currentY + 7, { width: colWidths[i] - 10, align: 'left' });
                    currentX += colWidths[i];
                });
                currentY += 25;
            };

            drawHeader();

            // Draw Data
            doc.font('Helvetica').fontSize(9).fillColor(colors.text);

            reportList.forEach((r, i) => {
                const rowHeight = 30;
                if (currentY + rowHeight > 550) {
                    doc.addPage({ margin: 30, size: 'A4', layout: 'landscape' });
                    currentY = 30;
                    drawHeader();
                }
                if (i % 2 === 1) {
                    doc.rect(30, currentY, 782, rowHeight).fill(colors.rowOdd);
                }
                let currentX = 30;
                doc.fillColor(colors.text);
                const drawCell = (text: string, colIndex: number, bold: boolean = false, color: string = colors.text) => {
                    if (bold) doc.font('Helvetica-Bold'); else doc.font('Helvetica');
                    doc.fillColor(color);
                    doc.text(safeText(text), currentX + 5, currentY + 8, {
                        width: colWidths[colIndex] - 10,
                        height: rowHeight - 16,
                        lineBreak: false,
                        ellipsis: true
                    });
                    currentX += colWidths[colIndex];
                };
                const dateStr = r.createdAt ? new Date(r.createdAt).toLocaleDateString('id-ID') : '-';
                const locationStr = r.building ? `${r.building}${r.location ? ` (${r.location})` : ''}` : '-';
                drawCell(r.id.toString(), 0, true);
                drawCell(dateStr, 1);
                drawCell(r.title || '-', 2);
                drawCell(r.categoryName || '-', 3);
                drawCell(locationStr, 4);
                drawCell(r.reporterName || 'Anonim', 5);
                drawCell(r.status ? r.status.toUpperCase() : '-', 6);
                drawCell(r.isEmergency ? 'DARURAT' : 'Normal', 7, !!r.isEmergency, r.isEmergency ? colors.danger : colors.text);
                currentY += rowHeight;
            });

            // --- FOOTER ---
            const range = doc.bufferedPageRange();
            for (let i = 0; i < range.count; i++) {
                doc.switchToPage(i);
                doc.fontSize(8).fillColor(colors.textLight).text(
                    `Halaman ${i + 1} dari ${range.count} - Laporan Kerusakan Fasilitas`,
                    30,
                    570,
                    { align: 'right', width: 782 }
                );
                doc.moveTo(30, 565).lineTo(812, 565).lineWidth(0.5).stroke(colors.border);
            }

            doc.end();
            const buffer = await pdfBufferPromise;
            set.headers['Content-Type'] = 'application/pdf';
            set.headers['Content-Disposition'] = 'attachment; filename=laporan_fasilitas_laporfsm.pdf';
            return buffer;
        } catch (e) {
            console.error('Error generating Reports PDF:', e);
            set.status = 500;
            return { error: 'Failed to generate PDF', details: String(e) };
        }
    })

    // Export Reports Excel
    .get('/reports/export/excel', async ({ set }) => {
        try {
            const reportList = await db
                .select({
                    id: reports.id,
                    title: reports.title,
                    description: reports.description,
                    status: reports.status,
                    building: reports.location,
                    location: reports.locationDetail,
                    isEmergency: reports.isEmergency,
                    createdAt: reports.createdAt,
                    reporterName: users.name,
                    categoryName: categories.name,
                })
                .from(reports)
                .leftJoin(users, eq(reports.userId, users.id))
                .leftJoin(categories, eq(reports.categoryId, categories.id))
                .orderBy(desc(reports.createdAt));

            const workbook = new ExcelJS.Workbook();
            const worksheet = workbook.addWorksheet('Laporan');

            worksheet.columns = [
                { header: 'ID', key: 'id', width: 10 },
                { header: 'Tanggal', key: 'date', width: 20 },
                { header: 'Judul', key: 'title', width: 30 },
                { header: 'Deskripsi', key: 'desc', width: 50 },
                { header: 'Kategori', key: 'category', width: 20 },
                { header: 'Gedung', key: 'building', width: 20 },
                { header: 'Detail Lokasi', key: 'location', width: 25 },
                { header: 'Pelapor', key: 'reporter', width: 20 },
                { header: 'Status', key: 'status', width: 15 },
                { header: 'Darurat', key: 'emergency', width: 10 },
            ];

            reportList.forEach(r => {
                worksheet.addRow({
                    id: r.id,
                    date: r.createdAt,
                    title: r.title,
                    desc: r.description,
                    category: r.categoryName,
                    building: r.building,
                    location: r.location,
                    reporter: r.reporterName,
                    status: r.status,
                    emergency: r.isEmergency ? 'YA' : 'TIDAK'
                });
            });

            const buffer = await workbook.xlsx.writeBuffer();
            set.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            set.headers['Content-Disposition'] = 'attachment; filename=laporan_fasilitas_laporfsm.xlsx';
            return buffer;
        } catch (e) {
            console.error('Error generating Reports Excel:', e);
            set.status = 500;
            return { error: 'Failed to generate Excel', details: String(e) };
        }
    })

    // Fetch System Logs
    .get('/logs', async () => {
        const logs = await db
            .select()
            .from(reportLogs)
            .orderBy(desc(reportLogs.timestamp))
            .limit(100);

        return {
            status: 'success',
            data: logs.map(l => ({
                id: l.id.toString(),
                action: l.action.charAt(0).toUpperCase() + l.action.slice(1),
                user: l.actorName,
                details: l.reason || `Status changed from ${l.fromStatus} to ${l.toStatus}`,
                time: l.timestamp,
                type: (l.reportId === null && ['verified', 'activated', 'suspended'].includes(l.action))
                    ? 'Verifikasi'
                    : (l.reportId === null || l.action === 'created') ? 'Admin' : 'Laporan'
            }))
        };
    })

    // Export Logs PDF
    .get('/logs/export/pdf', async ({ set }) => {
        try {
            const logs = await db
                .select()
                .from(reportLogs)
                .orderBy(desc(reportLogs.timestamp));

            const doc = new PDFDocument({ margin: 30, size: 'A4', layout: 'landscape', bufferPages: true });
            const chunks: Buffer[] = [];

            // Promise wrapper to handle stream completion and errors
            const pdfBufferPromise = new Promise<Buffer>((resolve, reject) => {
                doc.on('data', (chunk) => chunks.push(chunk));
                doc.on('end', () => resolve(Buffer.concat(chunks)));
                doc.on('error', (err) => reject(err));
            });

            // Helper to sanitize text for standard PDF fonts (removes emojis/unsupported chars)
            const safeText = (str: string | null | undefined): string => {
                if (!str) return '-';
                return str.replace(/[^\x20-\x7E\xA0-\xFF\n\r\t]/g, '').trim() || '-';
            };

            // --- STYLING CONSTANTS ---
            const colors = {
                primary: '#7C3AED', // Admin Purple 600
                secondary: '#8B5CF6', // Admin Purple 500
                text: '#1F2937',
                textLight: '#6B7280',
                border: '#E5E7EB',
                rowOdd: '#F9FAFB',
                white: '#FFFFFF'
            };

            // --- HEADER ---
            doc.font('Helvetica-Bold').fontSize(24).fillColor(colors.primary).text('Lapor FSM!', 30, 30);
            doc.fontSize(10).fillColor(colors.textLight).text('Sistem Informasi Pelaporan Fasilitas FSM Undip', 30, 55);

            doc.fontSize(14).fillColor(colors.text).text('LOG AKTIVITAS SISTEM', 400, 30, { align: 'right', width: 410 });
            doc.fontSize(9).fillColor(colors.textLight).text('Rekam Jejak Aktivitas User & Admin', 400, 50, { align: 'right', width: 410 });
            doc.fontSize(9).fillColor(colors.textLight).text(`Dicetak: ${new Date().toLocaleString('id-ID')}`, 400, 62, { align: 'right', width: 410 });

            doc.moveTo(30, 75).lineTo(812, 75).lineWidth(1).stroke(colors.primary);

            // --- SUMMARY STATISTICS ---
            const summaryY = 90;
            doc.roundedRect(30, summaryY, 782, 50, 5).fill(colors.rowOdd).stroke(colors.border);

            const totalLogs = logs.length;
            const adminActions = logs.filter(l => l.actorRole === 'admin').length;
            const userActions = logs.filter(l => l.actorRole === 'user' || l.actorRole === 'pelapor').length;
            const verifications = logs.filter(l => l.action === 'verified').length;

            const drawSummaryItem = (label: string, value: string, x: number) => {
                doc.fillColor(colors.textLight).fontSize(9).text(safeText(label), x, summaryY + 10, { align: 'center', width: 150 });
                doc.fillColor(colors.primary).font('Helvetica-Bold').fontSize(14).text(safeText(value), x, summaryY + 25, { align: 'center', width: 150 });
            };

            drawSummaryItem('Total Log', totalLogs.toString(), 30);
            drawSummaryItem('Admin Actions', adminActions.toString(), 220);
            drawSummaryItem('User Actions', userActions.toString(), 410);
            drawSummaryItem('Verifications', verifications.toString(), 600);

            // --- TABLE ---
            let currentY = 160;
            const colWidths = [130, 150, 120, 382]; // Total 782
            const headers = ['Waktu', 'Aktor (Nama & Role)', 'Aksi', 'Detail / Alasan'];

            // Draw Header
            const drawHeader = () => {
                doc.rect(30, currentY, 782, 25).fill(colors.primary);
                let currentX = 30;
                doc.fillColor(colors.white).font('Helvetica-Bold').fontSize(9);
                headers.forEach((header, i) => {
                    doc.text(safeText(header), currentX + 5, currentY + 7, { width: colWidths[i] - 10, align: 'left' });
                    currentX += colWidths[i];
                });
                currentY += 25;
            };

            drawHeader();

            // Draw Data
            doc.font('Helvetica').fontSize(9).fillColor(colors.text);

            logs.forEach((l, i) => {
                const rowHeight = 30;
                if (currentY + rowHeight > 550) {
                    doc.addPage({ margin: 30, size: 'A4', layout: 'landscape' });
                    currentY = 30;
                    drawHeader();
                }
                if (i % 2 === 1) {
                    doc.rect(30, currentY, 782, rowHeight).fill(colors.rowOdd);
                }
                let currentX = 30;
                doc.fillColor(colors.text);
                const drawCell = (text: string, colIndex: number, bold: boolean = false) => {
                    if (bold) doc.font('Helvetica-Bold'); else doc.font('Helvetica');
                    doc.text(safeText(text), currentX + 5, currentY + 8, {
                        width: colWidths[colIndex] - 10,
                        height: rowHeight - 16,
                        lineBreak: false,
                        ellipsis: true
                    });
                    currentX += colWidths[colIndex];
                };
                const timeStr = l.timestamp ? new Date(l.timestamp).toLocaleString('id-ID') : '-';
                const actorStr = `${l.actorName || 'Unknown'} (${l.actorRole || 'unknown'})`;
                const actionStr = l.action ? l.action.toUpperCase() : '-';
                const detailStr = l.reason || (l.fromStatus && l.toStatus ? `${l.fromStatus} → ${l.toStatus}` : '-');

                drawCell(timeStr, 0);
                drawCell(actorStr, 1, true);
                drawCell(actionStr, 2);
                drawCell(detailStr, 3);
                currentY += rowHeight;
            });

            // --- FOOTER ---
            const range = doc.bufferedPageRange();
            for (let i = 0; i < range.count; i++) {
                doc.switchToPage(i);
                doc.fontSize(8).fillColor(colors.textLight).text(
                    `Halaman ${i + 1} dari ${range.count} - Log Aktivitas Sistem`,
                    30,
                    570,
                    { align: 'right', width: 782 }
                );
                doc.moveTo(30, 565).lineTo(812, 565).lineWidth(0.5).stroke(colors.border);
            }

            doc.end();
            const buffer = await pdfBufferPromise;

            set.headers['Content-Type'] = 'application/pdf';
            set.headers['Content-Disposition'] = 'attachment; filename=log_aktivitas_sistem.pdf';
            return buffer;
        } catch (e) {
            console.error('Error generating Logs PDF:', e);
            set.status = 500;
            return { error: 'Failed to generate PDF', details: String(e) };
        }
    })

    // Export Logs Excel
    .get('/logs/export/excel', async ({ set }) => {
        try {
            const logsData = await db
                .select()
                .from(reportLogs)
                .orderBy(desc(reportLogs.timestamp));

            const workbook = new ExcelJS.Workbook();
            const worksheet = workbook.addWorksheet('Log Sistem');

            worksheet.columns = [
                { header: 'No', key: 'no', width: 5 },
                { header: 'Waktu', key: 'time', width: 20 },
                { header: 'Kategori', key: 'category', width: 20 },
                { header: 'Aktor (User)', key: 'actor', width: 25 },
                { header: 'Role', key: 'role', width: 15 },
                { header: 'Aksi', key: 'action', width: 20 },
                { header: 'Dari Status', key: 'from', width: 15 },
                { header: 'Ke Status', key: 'to', width: 15 },
                { header: 'Alasan / Detail', key: 'reason', width: 50 },
            ];

            // Styling header
            worksheet.getRow(1).height = 25;
            worksheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
            worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' } };
            worksheet.getRow(1).fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: '7C3AED' }
            };

            logsData.forEach((l, i) => {
                const category = l.reportId ? 'LAPORAN' : (l.action === 'verified' ? 'VERIFIKASI' : 'ADMIN');
                worksheet.addRow({
                    no: i + 1,
                    time: l.timestamp ? new Date(l.timestamp).toLocaleString('id-ID') : '-',
                    category,
                    actor: l.actorName,
                    role: l.actorRole,
                    action: l.action,
                    from: l.fromStatus,
                    to: l.toStatus,
                    reason: l.reason
                });
            });

            const buffer = await workbook.xlsx.writeBuffer();
            set.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            set.headers['Content-Disposition'] = 'attachment; filename=log_sistem_laporfsm.xlsx';
            return buffer;
        } catch (e) {
            console.error('Error generating Logs Excel:', e);
            set.status = 500;
            return { error: 'Failed' };
        }
    })


    // ==========================================
    // USER MANAGEMENT
    // ==========================================

    .get('/users', async () => {
        const userList = await db.select().from(users).orderBy(desc(users.createdAt));
        return { status: 'success', data: userList.map(u => mapToMobileUser(u)) };
    })

    .get('/users/pending', async () => {
        const pendingList = await db.select().from(users).where(eq(users.isVerified, false)).orderBy(desc(users.createdAt));
        return { status: 'success', data: pendingList.map(u => mapToMobileUser(u)) };
    })

    .post('/users/:id/verify', async ({ params }) => {
        const userId = parseInt(params.id);

        // Get user details first
        const user = await db.select().from(users).where(eq(users.id, userId)).limit(1);
        if (user.length === 0) return { status: 'error', message: 'User tidak ditemukan' };

        const userData = user[0];

        // Check if it's an external user (non-UNDIP)
        const isUndipEmail = (email: string) => {
            const lowerEmail = email.toLowerCase();
            return lowerEmail.endsWith('@undip.ac.id') ||
                lowerEmail.endsWith('@students.undip.ac.id') ||
                lowerEmail.endsWith('@live.undip.ac.id') ||
                lowerEmail.endsWith('@lecturer.undip.ac.id') ||
                lowerEmail.endsWith('@staff.undip.ac.id');
        };

        const isExternal = !isUndipEmail(userData.email);

        // Update user as verified
        const updated = await db.update(users).set({ isVerified: true }).where(eq(users.id, userId)).returning();

        // For external users, generate activation token and send email
        if (isExternal) {
            const crypto = require('crypto');
            const activationToken = crypto.randomBytes(32).toString('hex');
            const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

            // Store token in database
            await db.update(users)
                .set({
                    emailVerificationToken: activationToken,
                    emailVerificationExpiresAt: expiresAt
                })
                .where(eq(users.id, userId));

            // Send activation email
            const apiUrl = process.env.API_URL || 'http://localhost:3000';
            const activationLink = `${apiUrl}/auth/activate?token=${activationToken}&email=${encodeURIComponent(userData.email)}`;

            console.log(`[ADMIN VERIFY] Activation token for ${userData.email}: ${activationToken}`);
            try {
                // Import EmailService
                const { EmailService } = await import('../../services/email.service');
                await EmailService.sendActivationEmail(userData.email, userData.name, activationLink, false);
            } catch (err) {
                console.error('[ADMIN VERIFY] Failed to send activation email:', err);
            }
        } else {
            // For UNDIP users, just send notification
            await NotificationService.notifyUser(updated[0].id, 'Akun Terverifikasi', 'Selamat! Akun Anda telah diverifikasi oleh admin.');
        }

        await db.insert(reportLogs).values({
            action: 'verified', actorId: 'admin', actorName: 'Admin System', actorRole: 'admin',
            reason: `Admin memverifikasi user: ${updated[0].name}${isExternal ? ' (External - Activation email sent)' : ''}`,
        });

        return {
            status: 'success',
            message: isExternal ? 'User berhasil diverifikasi dan email aktivasi telah dikirim' : 'User berhasil diverifikasi',
            data: mapToMobileUser(updated[0])
        };
    })

    .put('/users/:id/suspend', async ({ params, body }) => {
        const updated = await db.update(users).set({ isActive: body.isActive }).where(eq(users.id, parseInt(params.id))).returning();
        if (updated.length === 0) return { status: 'error', message: 'User tidak ditemukan' };
        const action = body.isActive ? 'diaktifkan' : 'dinonaktifkan';
        await db.insert(reportLogs).values({
            action: body.isActive ? 'activated' : 'suspended', actorId: 'admin', actorName: 'Admin System', actorRole: 'admin',
            reason: `Admin ${action} user: ${updated[0].name}`,
        });
        return { status: 'success', message: `User berhasil ${action}`, data: mapToMobileUser(updated[0]) };
    }, { body: t.Object({ isActive: t.Boolean() }) })

    .get('/users/:id', async ({ params }) => {
        const user = await db.select().from(users).where(eq(users.id, parseInt(params.id))).limit(1);
        if (user.length === 0) return { status: 'error', message: 'User tidak ditemukan' };
        const userReports = await db.select().from(reports).where(eq(reports.userId, parseInt(params.id))).orderBy(desc(reports.createdAt));
        return { status: 'success', data: { user: mapToMobileUser(user[0]), reports: userReports.map(r => mapToMobileReport(r)) } };
    })

    .put('/reports/:id/force-close', async ({ params, body }) => {
        const reportId = parseInt(params.id);
        const existingReport = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (existingReport.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };
        const updatedReport = await db.update(reports).set({
            status: 'selesai', handlingCompletedAt: new Date(), handlerNotes: `[Admin Force Close] ${body.reason}`,
        }).where(eq(reports.id, reportId)).returning();
        await db.insert(reportLogs).values({
            reportId, fromStatus: existingReport[0].status, toStatus: 'selesai', action: 'force_close',
            actorId: 'admin', actorName: 'Admin System', actorRole: 'admin', reason: body.reason,
        });
        if (updatedReport[0].userId) {
            await NotificationService.notifyUser(updatedReport[0].userId, 'Laporan Ditutup Admin', `Laporan Anda telah diselesaikan oleh Admin: ${body.reason}`, 'info', reportId);
        }
        return { status: 'success', message: 'Laporan berhasil ditutup paksa', data: mapToMobileReport(updatedReport[0]) };
    }, { body: t.Object({ reason: t.String() }) })

    .delete('/users/:id', async ({ params }) => {
        const deleted = await db.delete(users).where(eq(users.id, parseInt(params.id))).returning();
        if (deleted.length === 0) return { status: 'error', message: 'User tidak ditemukan' };
        return { status: 'success', message: 'User berhasil dihapus' };
    });

