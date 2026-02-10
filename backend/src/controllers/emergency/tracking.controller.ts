import { Elysia, t } from 'elysia';

export const trackingController = new Elysia()
    .ws('/ws/tracking/:reportId', {
        params: t.Object({
            reportId: t.String()
        }),
        body: t.Object({
            latitude: t.Number(),
            longitude: t.Number(),
            role: t.String(), // 'pelapor' or 'staff'
            senderName: t.String()
        }),
        open(ws) {
            const { reportId } = ws.data.params;
            ws.subscribe(`report-${reportId}`);
            console.log(`[WS-TRACKING] Local: Connection opened for report ${reportId}`);
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
