import { Elysia, t } from 'elysia';
import { db } from '../db';
import { notifications } from '../db/schema';
import { eq, desc, and, or } from 'drizzle-orm';
import { mapToMobileNotification } from '../utils/mapper';

export const notificationController = new Elysia({ prefix: '/notifications' })
    // Get notifications for a user OR staff
    .get('/:type/:id', async ({ params, set }) => {
        const { type, id } = params;
        const targetId = parseInt(id);

        if (isNaN(targetId)) {
            set.status = 400;
            return { status: 'error', message: 'Invalid ID format' };
        }

        const whereClause = type === 'user' 
            ? eq(notifications.userId, targetId)
            : eq(notifications.staffId, targetId);

        const result = await db
            .select()
            .from(notifications)
            .where(whereClause)
            .orderBy(desc(notifications.createdAt));

        return {
            status: 'success',
            data: result.map(n => mapToMobileNotification(n)),
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
            data: mapToMobileNotification(updated[0])
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
    
    // Delete all for user/staff
    .delete('/all/:type/:id', async ({ params }) => {
        const { type, id } = params;
        const targetId = parseInt(id);

        const whereClause = type === 'user' 
            ? eq(notifications.userId, targetId)
            : eq(notifications.staffId, targetId);

        await db.delete(notifications).where(whereClause);

        return { status: 'success', message: 'All notifications deleted' };
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
