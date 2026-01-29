import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { staff, users, categories, reports, reportLogs } from '../../db/schema';
import { eq, desc, count, sql, and, not } from 'drizzle-orm';

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
                createdAt: staff.createdAt,
            })
            .from(staff)
            .orderBy(desc(staff.createdAt));

        return {
            status: 'success',
            data: staffList.map(s => ({ ...s, id: s.id.toString() })),
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
            },
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
            data: userList.map(u => ({ ...u, id: u.id.toString(), password: '' })),
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
            data: pendingList.map(u => ({ ...u, id: u.id.toString(), password: '' })),
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
        
        return { 
            status: 'success', 
            message: 'User berhasil diverifikasi',
            data: { ...updated[0], id: updated[0].id.toString(), password: '' }
        };
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
