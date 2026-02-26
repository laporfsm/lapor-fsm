import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reportLogs } from '../../db/schema';
import { desc, eq } from 'drizzle-orm';
import { logEventEmitter, LOG_EVENTS } from '../../utils/events';

// Re-implementation for robust stream handling
export const logStreamController = new Elysia()
    .get('/reports/:id/logs/stream', ({ params }) => {
        const reportId = parseInt(params.id);
        let cleanup: (() => void) | undefined;

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
                    try {
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
                    } catch (e) {
                        console.error(`[SSE-LOG] Error fetching logs for report ${reportId}:`, e);
                    }
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

                // Add listeners
                logEventEmitter.on(LOG_EVENTS.NEW_LOG, onNewLog);
                logEventEmitter.on(LOG_EVENTS.TRACKING_UPDATE, onTrackingUpdate);

                // Initial logs
                await sendLogs();

                // Keep-alive ping
                const keepAlive = setInterval(() => {
                    send({ type: 'ping' });
                }, 30000);

                // Define cleanup
                cleanup = () => {
                    logEventEmitter.off(LOG_EVENTS.NEW_LOG, onNewLog);
                    logEventEmitter.off(LOG_EVENTS.TRACKING_UPDATE, onTrackingUpdate);
                    clearInterval(keepAlive);
                };
            },
            cancel() {
                if (cleanup) cleanup();
            }
        }), {
            headers: {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
            }
        });
    });
