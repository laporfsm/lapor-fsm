import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { staff } from '../../db/schema';
import { eq } from 'drizzle-orm';

export const staffController = new Elysia({ prefix: '/staff' })
    // Staff Login (Teknisi, Supervisor, Admin)
    .post('/login', async ({ body }) => {
        const foundStaff = await db
            .select()
            .from(staff)
            .where(eq(staff.email, body.email))
            .limit(1);

        if (foundStaff.length === 0) {
            return {
                status: 'error',
                message: 'Email tidak ditemukan'
            };
        }

        const staffMember = foundStaff[0];

        // Check if staff is active
        if (!staffMember.isActive) {
            return {
                status: 'error',
                message: 'Akun tidak aktif'
            };
        }

        // Simple password check (in production, use bcrypt)
        if (staffMember.password !== body.password) {
            return {
                status: 'error',
                message: 'Password salah'
            };
        }

        return {
            status: 'success',
            message: 'Login berhasil',
            data: {
                id: staffMember.id,
                name: staffMember.name,
                email: staffMember.email,
                phone: staffMember.phone,
                role: staffMember.role,
                token: `staff-jwt-token-${staffMember.id}`, // In production, use real JWT
            },
        };
    }, {
        body: t.Object({
            email: t.String(),
            password: t.String(),
        }),
    })

    // Get Staff Profile
    .get('/me/:id', async ({ params }) => {
        const foundStaff = await db
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
            .where(eq(staff.id, parseInt(params.id)))
            .limit(1);

        if (foundStaff.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
        }

        return {
            status: 'success',
            data: foundStaff[0],
        };
    });
