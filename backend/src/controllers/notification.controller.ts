import { Elysia, t } from 'elysia';
import { db } from '../db';
import { notifications, users, staff } from '../db/schema';
import { eq, desc, and, or } from 'drizzle-orm';
import { mapToMobileNotification } from '../utils/mapper';

export const notificationController = new Elysia({ prefix: '/notifications' })
    // Save FCM Token
    .post('/fcm-token', async ({ body }) => {
        const { userId, role, token } = body;
        const id = typeof userId === 'string' ? parseInt(userId) : userId;

        if (role === 'user' || role === 'pelapor') {
            await db.update(users)
                .set({ fcmToken: token })
                .where(eq(users.id, id));
        } else {
            await db.update(staff)
                .set({ fcmToken: token })
                .where(eq(staff.id, id));
        }

        return { status: 'success', message: 'FCM Token updated' };
    }, {
        body: t.Object({
            userId: t.Any(), // Can be string or number
            role: t.String(),
            token: t.String()
        })
    })

    // Get notifications for a user OR staff
    .get('/:type/:id', async ({ params, set }) => {
        try {
            const { type, id } = params;
            const targetId = parseInt(id);

            if (isNaN(targetId)) {
                set.status = 400;
                return { status: 'error', message: 'Invalid ID format' };
            }

            console.log(`[Notification] Fetching for ${type} ID: ${targetId}`);

            // Fix: ensure correct column usage based on type
            // Note: Schema has userId (nullable) AND staffId (nullable)
            // If type is 'user', look for userId. If 'staff', look for staffId.
            const whereClause = type === 'user'
                ? eq(notifications.userId, targetId)
                : eq(notifications.staffId, targetId);

            const result = await db
                .select()
                .from(notifications)
                .where(whereClause)
                .orderBy(desc(notifications.createdAt));
            
            console.log(`[Notification] Found ${result.length} notifications`);

            // Use try-catch map to avoid crash on single item error
            const mappedData = result.map(n => {
                try {
                    return mapToMobileNotification(n);
                } catch (e) {
                    console.error('[Notification] Mapper error:', e);
                    return null;
                }
            }).filter(n => n !== null);

            return {
                status: 'success',
                data: mappedData,
            };
        } catch (error) {
            console.error('[Notification] Error:', error);
            set.status = 500;
            return { status: 'error', message: 'Internal Server Error' };
        }
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
