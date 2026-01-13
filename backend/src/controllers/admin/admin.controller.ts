import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { staff, users, categories, reports, reportLogs } from '../../db/schema';
import { eq, desc, count, sql } from 'drizzle-orm';

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
                isActive: staff.isActive,
                createdAt: staff.createdAt,
            })
            .from(staff)
            .orderBy(desc(staff.createdAt));

        return {
            status: 'success',
            data: staffList,
        };
    })

    // Create new staff
    .post('/staff', async ({ body }) => {
        // Check if email already exists
        const existing = await db
            .select()
            .from(staff)
            .where(eq(staff.email, body.email))
            .limit(1);

        if (existing.length > 0) {
            return { status: 'error', message: 'Email sudah terdaftar' };
        }

        const newStaff = await db.insert(staff).values({
            name: body.name,
            email: body.email,
            phone: body.phone,
            password: body.password, // In production, hash this
            role: body.role,
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
            role: t.String(), // 'teknisi', 'supervisor', 'admin'
        }),
    })

    // Update staff
    .put('/staff/:id', async ({ params, body }) => {
        const staffId = parseInt(params.id);

        const updateData: any = {};
        if (body.name) updateData.name = body.name;
        if (body.phone) updateData.phone = body.phone;
        if (body.role) updateData.role = body.role;
        if (body.isActive !== undefined) updateData.isActive = body.isActive;
        if (body.password) updateData.password = body.password;

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
            phone: t.Optional(t.String()),
            role: t.Optional(t.String()),
            isActive: t.Optional(t.Boolean()),
            password: t.Optional(t.String()),
        }),
    })

    // Delete/Deactivate staff
    .delete('/staff/:id', async ({ params }) => {
        const staffId = parseInt(params.id);

        const updated = await db
            .update(staff)
            .set({ isActive: false })
            .where(eq(staff.id, staffId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
        }

        return {
            status: 'success',
            message: 'Staff berhasil dinonaktifkan',
        };
    })

    // ==========================================
    // CATEGORY MANAGEMENT
    // ==========================================

    // Get all categories
    .get('/categories', async () => {
        const categoryList = await db
            .select()
            .from(categories)
            .orderBy(categories.type, categories.name);

        return {
            status: 'success',
            data: categoryList,
        };
    })

    // Create category
    .post('/categories', async ({ body }) => {
        const newCategory = await db.insert(categories).values({
            name: body.name,
            type: body.type,
            icon: body.icon,
        }).returning();

        return {
            status: 'success',
            message: 'Kategori berhasil ditambahkan',
            data: newCategory[0],
        };
    }, {
        body: t.Object({
            name: t.String(),
            type: t.String(), // 'emergency' or 'non-emergency'
            icon: t.Optional(t.String()),
        }),
    })

    // Update category
    .put('/categories/:id', async ({ params, body }) => {
        const categoryId = parseInt(params.id);

        const updated = await db
            .update(categories)
            .set({
                name: body.name,
                type: body.type,
                icon: body.icon,
            })
            .where(eq(categories.id, categoryId))
            .returning();

        if (updated.length === 0) {
            return { status: 'error', message: 'Kategori tidak ditemukan' };
        }

        return {
            status: 'success',
            message: 'Kategori berhasil diupdate',
            data: updated[0],
        };
    }, {
        body: t.Object({
            name: t.String(),
            type: t.String(),
            icon: t.Optional(t.String()),
        }),
    })

    // Delete category
    .delete('/categories/:id', async ({ params }) => {
        const categoryId = parseInt(params.id);

        // Check if category is being used
        const usedInReports = await db
            .select({ count: count() })
            .from(reports)
            .where(eq(reports.categoryId, categoryId));

        if ((usedInReports[0]?.count || 0) > 0) {
            return {
                status: 'error',
                message: 'Kategori tidak dapat dihapus karena sedang digunakan'
            };
        }

        await db.delete(categories).where(eq(categories.id, categoryId));

        return {
            status: 'success',
            message: 'Kategori berhasil dihapus',
        };
    })

    // ==========================================
    // DASHBOARD ANALYTICS
    // ==========================================

    .get('/dashboard', async () => {
        // Total reports
        const totalReports = await db
            .select({ count: count() })
            .from(reports);

        // Reports by status
        const reportsByStatus = await db
            .select({
                status: reports.status,
                count: count(),
            })
            .from(reports)
            .groupBy(reports.status);

        // Reports by category
        const reportsByCategory = await db
            .select({
                categoryId: reports.categoryId,
                categoryName: categories.name,
                count: count(),
            })
            .from(reports)
            .leftJoin(categories, eq(reports.categoryId, categories.id))
            .groupBy(reports.categoryId, categories.name);

        // Emergency vs Non-emergency
        const emergencyStats = await db
            .select({
                isEmergency: reports.isEmergency,
                count: count(),
            })
            .from(reports)
            .groupBy(reports.isEmergency);

        // Staff count by role
        const staffByRole = await db
            .select({
                role: staff.role,
                count: count(),
            })
            .from(staff)
            .where(eq(staff.isActive, true))
            .groupBy(staff.role);

        // Total users (reporters)
        const totalUsers = await db
            .select({ count: count() })
            .from(users);

        // Recent reports (last 7 days)
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const recentReports = await db
            .select({ count: count() })
            .from(reports)
            .where(sql`${reports.createdAt} >= ${sevenDaysAgo}`);

        // Average handling time (for completed reports)
        // This is a simplified calculation
        const completedWithTime = await db
            .select({
                id: reports.id,
                handledAt: reports.handledAt,
                completedAt: reports.completedAt,
            })
            .from(reports)
            .where(eq(reports.status, 'selesai'))
            .limit(100);

        let avgHandlingMinutes = 0;
        const validReports = completedWithTime.filter(r => r.handledAt && r.completedAt);
        if (validReports.length > 0) {
            const totalMinutes = validReports.reduce((sum, r) => {
                const diff = new Date(r.completedAt!).getTime() - new Date(r.handledAt!).getTime();
                return sum + (diff / 60000);
            }, 0);
            avgHandlingMinutes = Math.round(totalMinutes / validReports.length);
        }

        return {
            status: 'success',
            data: {
                totalReports: totalReports[0]?.count || 0,
                totalUsers: totalUsers[0]?.count || 0,
                recentReports: recentReports[0]?.count || 0,
                avgHandlingMinutes,
                reportsByStatus: reportsByStatus.reduce((acc, curr) => {
                    acc[curr.status || 'unknown'] = curr.count;
                    return acc;
                }, {} as Record<string, number>),
                reportsByCategory,
                emergencyStats: {
                    emergency: emergencyStats.find(e => e.isEmergency)?.count || 0,
                    nonEmergency: emergencyStats.find(e => !e.isEmergency)?.count || 0,
                },
                staffByRole: staffByRole.reduce((acc, curr) => {
                    acc[curr.role] = curr.count;
                    return acc;
                }, {} as Record<string, number>),
            },
        };
    })

    // Get all users (reporters)
    .get('/users', async () => {
        const userList = await db
            .select({
                id: users.id,
                name: users.name,
                email: users.email,
                phone: users.phone,
                faculty: users.faculty,
                department: users.department,
                createdAt: users.createdAt,
            })
            .from(users)
            .orderBy(desc(users.createdAt));

        return {
            status: 'success',
            data: userList,
        };
    });
