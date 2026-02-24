import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reportLogs } from '../../db/schema';
import { desc, eq } from 'drizzle-orm';
import { logEventEmitter, LOG_EVENTS } from '../../utils/events';

// Re-implementation for robust stream handling
export const logStreamController = new Elysia()
    .get('/reports/:id/logs/stream', ({ params }) => {
        const reportId = parseInt(params.id);

        return new Response(new ReadableStream({
            async start(controller) {
                const encoder = new TextEncoder();
                const send = (data: any) => {
                    try {
                        controller.enqueue(encoder.encode(`data: ${JSON.stringify(data)}\n\n`));
                    } catch (e) {
                        // Controller might be closed
                    }
                };

                const sendLogs = async () => {
                    const logs = await db
                        .select()
                        .from(reportLogs)
                        .where(eq(reportLogs.reportId, reportId))
                        .orderBy(desc(reportLogs.timestamp));

                    send({
                        type: 'logs',
                        logs: logs.map(l => ({
                            ...l,
                            actorName: l.actorName || 'Sistem',
                            actorRole: l.actorRole
                        }))
                    });
                };

                const onNewLog = (id: string | number) => {
                    if (id.toString() === reportId.toString()) sendLogs();
                };

                const onTrackingUpdate = (data: any) => {
                    if (data.reportId.toString() === reportId.toString()) {
                        send({
                            type: 'tracking',
                            ...data
                        });
                    }
                };

                logEventEmitter.on(LOG_EVENTS.NEW_LOG, onNewLog);
                logEventEmitter.on(LOG_EVENTS.TRACKING_UPDATE, onTrackingUpdate);

                // Send initial logs
                await sendLogs();

                // Handle cancellation
                const controllerAny = controller as any;
                if (controllerAny.signal) {
                    controllerAny.signal.addEventListener('abort', () => {
                        logEventEmitter.off(LOG_EVENTS.NEW_LOG, onNewLog);
                        logEventEmitter.off(LOG_EVENTS.TRACKING_UPDATE, onTrackingUpdate);
                    });
                }
            },
            cancel() {
                // ReadableStream cancel
            }
        }), {
            headers: {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
            }
        });
    });
