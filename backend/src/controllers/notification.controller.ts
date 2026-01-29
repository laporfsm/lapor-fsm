import { Elysia, t } from 'elysia';
import { db } from '../db';
import { notifications } from '../db/schema';
import { eq, desc, and, or } from 'drizzle-orm';

export const notificationController = new Elysia({ prefix: '/notifications' })
    // Get notifications for a user OR staff
    .get('/:type/:id', async ({ params }) => {
        const { type, id } = params;
        const targetId = parseInt(id);

        let query = db.select().from(notifications);
        
        if (type === 'user') {
            // @ts-ignore
            query = query.where(eq(notifications.userId, targetId));
        } else {
            // @ts-ignore
            query = query.where(eq(notifications.staffId, targetId));
        }

        const result = await query.orderBy(desc(notifications.createdAt));

        return {
            status: 'success',
            data: result.map(n => ({
                ...n,
                id: n.id.toString(),
                userId: n.userId?.toString(),
                staffId: n.staffId?.toString(),
            })),
        };
    })

    // Mark notification as read
    .patch('/:id/read', async ({ params }) => {
        const updated = await db
            .update(notifications)
            .set({ isRead: true })
            .where(eq(notifications.id, parseInt(params.id)))
            .returning();

        if (updated.length === 0) return { status: 'error', message: 'Notification not found' };

        return { 
            status: 'success', 
            data: {
                ...updated[0],
                id: updated[0].id.toString()
            }
        };
    })

    // Mark all as read
    .post('/read-all', async ({ body }) => {
        const { type, id } = body;
        const targetId = parseInt(id);

        const whereClause = type === 'user' 
            ? eq(notifications.userId, targetId)
            : eq(notifications.staffId, targetId);

        await db
            .update(notifications)
            .set({ isRead: true })
            .where(whereClause);

        return { status: 'success', message: 'All notifications marked as read' };
    }, {
        body: t.Object({
            type: t.Enum({ user: 'user', staff: 'staff' }),
            id: t.String(),
        })
    })

    // Delete notification
    .delete('/:id', async ({ params }) => {
        const deleted = await db
            .delete(notifications)
            .where(eq(notifications.id, parseInt(params.id)))
            .returning();

        if (deleted.length === 0) return { status: 'error', message: 'Notification not found' };
        return { status: 'success', message: 'Notification deleted' };
    });
