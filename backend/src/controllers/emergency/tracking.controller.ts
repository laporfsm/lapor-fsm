import { Elysia, t } from 'elysia';
import { jwt } from '@elysiajs/jwt';

import { logEventEmitter, LOG_EVENTS } from '../../utils/events';

export const trackingController = new Elysia()
    .use(
        jwt({
            name: 'jwt',
            secret: process.env.JWT_SECRET || 'lapor-fsm-secret-key-change-in-production'
        })
    )
    .post('/tracking/:reportId', async ({ params, body, jwt, request }) => {
        const { reportId } = params;
        const authHeader = request.headers.get('authorization');
        const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;

        if (!token) return { status: 'error', message: 'No token provided' };

        const payload = await jwt.verify(token);
        if (!payload) return { status: 'error', message: 'Invalid token' };

        // Emit tracking update to be broadcast via SSE
        logEventEmitter.emit(LOG_EVENTS.TRACKING_UPDATE, {
            reportId,
            ...body as any,
            timestamp: new Date().toISOString()
        });

        console.log(`[TRACKING-POST] Update received from ${(body as any).senderName} for report ${reportId}`);
        return { status: 'success' };
    }, {
        params: t.Object({
            reportId: t.String()
        }),
        body: t.Object({
            latitude: t.Number(),
            longitude: t.Number(),
            role: t.String(),
            senderName: t.String()
        })
    });
