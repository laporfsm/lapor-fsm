import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { staff, users, categories, reports, reportLogs } from '../../db/schema';
import { eq, desc, count, sql, and, or, not, gte } from 'drizzle-orm';
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
                managedBuilding: staff.managedBuilding,
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
            managedBuilding: body.managedBuilding,
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
            managedBuilding: t.Optional(t.String()),
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
            managedBuilding: t.Optional(t.String()),
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

        return {
            status: 'success',
            data: {
                totalReports: totalReports[0]?.count || 0,
                totalUsers: totalUsers[0]?.count || 0,
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
        // 1. User Growth (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const growthData = await db.select({
            date: sql`DATE(${users.createdAt})`,
            count: count()
        })
        .from(users)
        .where(sql`${users.createdAt} >= ${thirtyDaysAgo}`)
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
            'Pelapor': Number(totalPelapor[0].count)
        };
        roleDistributionStaff.forEach(s => {
            const roleName = s.role.charAt(0).toUpperCase() + s.role.slice(1);
            distribution[roleName] = Number(s.count);
        });

        // 3. Report Volume by Category (Top 5)
        const reportVolume = await db.select({
            categoryName: categories.name,
            total: count()
        })
        .from(reports)
        .leftJoin(categories, eq(reports.categoryId, categories.id))
        .groupBy(categories.name)
        .orderBy(desc(count()))
        .limit(5);

        return {
            status: 'success',
            data: {
                userGrowth: growthData.map(g => ({
                    date: new Date(g.date as string).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }),
                    value: Number(g.count)
                })),
                activeUsers: distribution['Pelapor'] || 0, // Simplified active users
                totalLogin: 120, // Placeholder for login tracking if not available
                userDistribution: distribution,
                reportVolume: reportVolume.map(rv => ({
                    dept: rv.categoryName || 'Lainnya',
                    in: Number(rv.total),
                    out: Math.floor(Number(rv.total) * 0.8) // Simulated "done" count for now
                })),
                appUsage: [] // Removed mock app usage
            }
        };
    })

    // Fetch System Logs (Filtered to User actions)
    .get('/logs', async () => {
        const logs = await db
            .select()
            .from(reportLogs)
            .where(or(
                eq(reportLogs.action, 'register'),
                eq(reportLogs.action, 'verify_email'),
                eq(reportLogs.action, 'verified'),
                eq(reportLogs.action, 'suspended'),
                eq(reportLogs.action, 'activated')
            ))
            .orderBy(desc(reportLogs.timestamp))
            .limit(50);

        return {
            status: 'success',
            data: logs.map(l => ({
                id: l.id.toString(),
                action: l.action.charAt(0).toUpperCase() + l.action.slice(1),
                user: l.actorName,
                details: l.reason || `Status changed from ${l.fromStatus} to ${l.toStatus}`,
                time: l.timestamp,
                type: l.action === 'created' ? 'Laporan' : (l.actorRole === 'admin' ? 'User' : 'Laporan')
            }))
        };
    })

    // ==========================================
    // USER MANAGEMENT
    // ==========================================

    // Get all users
    .get('/users', async () => {
        const userList = await db
            .select()
            .from(users)
            .orderBy(desc(users.createdAt));

        return {
            status: 'success',
            data: userList.map(u => mapToMobileUser(u)),
        };
    })

    // Get pending users (unverified)
    .get('/users/pending', async () => {
        const pendingList = await db
            .select()
            .from(users)
            .where(eq(users.isVerified, false))
            .orderBy(desc(users.createdAt));

        return {
            status: 'success',
            data: pendingList.map(u => mapToMobileUser(u)),
        };
    })

    // Verify user
    .post('/users/:id/verify', async ({ params }) => {
        const updated = await db
            .update(users)
            .set({ isVerified: true })
            .where(eq(users.id, parseInt(params.id)))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'User tidak ditemukan' };

        // Notify User
        await NotificationService.notifyUser(updated[0].id, 'Akun Terverifikasi', 'Selamat! Akun Anda telah diverifikasi oleh admin. Anda sekarang dapat mengirim laporan.');

        return {
            status: 'success',
            message: 'User berhasil diverifikasi',
            data: mapToMobileUser(updated[0])
        };
    })

    // Suspend/Activate User
    .put('/users/:id/suspend', async ({ params, body }) => {
        const updated = await db
            .update(users)
            .set({ isActive: body.isActive })
            .where(eq(users.id, parseInt(params.id)))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'User tidak ditemukan' };

        const action = body.isActive ? 'diaktifkan' : 'dinonaktifkan';
        return {
            status: 'success',
            message: `User berhasil ${action}`,
            data: mapToMobileUser(updated[0])
        };
    }, {
        body: t.Object({
            isActive: t.Boolean(),
        }),
    })

    // Get User Details (Inspection)
    .get('/users/:id', async ({ params }) => {
        const user = await db.select().from(users).where(eq(users.id, parseInt(params.id))).limit(1);
        if (user.length === 0) return { status: 'error', message: 'User tidak ditemukan' };

        // Get user reports history
        const userReports = await db.select().from(reports).where(eq(reports.userId, parseInt(params.id))).orderBy(desc(reports.createdAt));

        return {
            status: 'success',
            data: {
                user: mapToMobileUser(user[0]),
                reports: userReports.map(r => mapToMobileReport(r)),
            }
        };
    })

    // Force Close Report
    .put('/reports/:id/force-close', async ({ params, body }) => {
        const reportId = parseInt(params.id);

        const existingReport = await db.select().from(reports).where(eq(reports.id, reportId)).limit(1);
        if (existingReport.length === 0) return { status: 'error', message: 'Laporan tidak ditemukan' };

        const updatedReport = await db
            .update(reports)
            .set({
                status: 'selesai',
                handlingCompletedAt: new Date(),
                handlerNotes: `[Admin Force Close] ${body.reason}`,
            })
            .where(eq(reports.id, reportId))
            .returning();

        // Log the action
        await db.insert(reportLogs).values({
            reportId: reportId,
            fromStatus: existingReport[0].status,
            toStatus: 'selesai',
            action: 'force_close',
            actorId: 'admin',
            actorName: 'Admin System',
            actorRole: 'admin',
            reason: body.reason,
        });

        // Notify User
        if (updatedReport[0].userId) {
            await NotificationService.notifyUser(updatedReport[0].userId, 'Laporan Ditutup Admin', `Laporan Anda telah diselesaikan oleh Admin: ${body.reason}`);
        }

        return {
            status: 'success',
            message: 'Laporan berhasil ditutup paksa',
            data: mapToMobileReport(updatedReport[0])
        };
    }, {
        body: t.Object({
            reason: t.String(),
        }),
    })

    // Delete user
    .delete('/users/:id', async ({ params }) => {
        const deleted = await db
            .delete(users)
            .where(eq(users.id, parseInt(params.id)))
            .returning();

        if (deleted.length === 0) return { status: 'error', message: 'User tidak ditemukan' };
        return { status: 'success', message: 'User berhasil dihapus' };
    });
