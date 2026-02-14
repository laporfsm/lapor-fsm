import { Elysia, t } from 'elysia';
import { jwt } from '@elysiajs/jwt';

export const trackingController = new Elysia()
    .use(
        jwt({
            name: 'jwt',
            secret: process.env.JWT_SECRET || 'lapor-fsm-secret-key-change-in-production'
        })
    )
    .ws('/ws/tracking/:reportId', {
        query: t.Object({
            token: t.Optional(t.String())
        }),
        params: t.Object({
            reportId: t.String()
        }),
        body: t.Object({
            latitude: t.Number(),
            longitude: t.Number(),
            role: t.String(), // 'pelapor' or 'staff'
            senderName: t.String()
        }),
        async open(ws) {
            const { reportId } = ws.data.params;
            const token = ws.data.query.token;

            if (!token) {
                console.log(`[WS-TRACKING] Unauthorized: No token provided for report ${reportId}`);
                ws.close();
                return;
            }

            const payload = await ws.data.jwt.verify(token);
            if (!payload) {
                console.log(`[WS-TRACKING] Unauthorized: Invalid token for report ${reportId}`);
                ws.close();
                return;
            }

            ws.subscribe(`report-${reportId}`);
            console.log(`[WS-TRACKING] Authorized: Connection opened for report ${reportId} (User: ${payload.id})`);
        },
        message(ws, message) {
            const { reportId } = ws.data.params;

            // Broadcast the location update to all subscribers in the room
            // including the sender (or the client can handle local state differently)
            ws.publish(`report-${reportId}`, {
                action: 'location_update',
                reportId,
                ...message,
                timestamp: new Date().toISOString()
            });

            console.log(`[WS-TRACKING] Broadcast from ${message.senderName} (${message.role}) for report ${reportId}`);
        },
        close(ws) {
            const { reportId } = ws.data.params;
            ws.unsubscribe(`report-${reportId}`);
            console.log(`[WS-TRACKING] Connection closed for report ${reportId}`);
        }
    });
