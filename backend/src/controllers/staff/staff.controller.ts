import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { staff } from '../../db/schema';
import { eq } from 'drizzle-orm';

export const staffController = new Elysia({ prefix: '/staff' })
    // Get Staff Profile
    .get('/me/:id', async ({ params }) => {
        const foundStaff = await db
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
            .where(eq(staff.id, parseInt(params.id)))
            .limit(1);

        if (foundStaff.length === 0) {
            return { status: 'error', message: 'Staff tidak ditemukan' };
        }

        return {
            status: 'success',
            data: foundStaff[0],
        };
    })

    // Update Profile
    .patch('/me/:id', async ({ params, body }) => {
        const staffId = parseInt(params.id);
        const updateData: any = {};
        if (body.name) updateData.name = body.name;
        if (body.phone) updateData.phone = body.phone;
        
        const updated = await db.update(staff)
            .set(updateData)
            .where(eq(staff.id, staffId))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Staff tidak ditemukan' };
        
        return { status: 'success', data: updated[0] };
    }, {
        body: t.Object({
            name: t.Optional(t.String()),
            phone: t.Optional(t.String()),
        })
    });
