import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reportLogs } from '../../db/schema';
import { desc, eq } from 'drizzle-orm';
import { logEventEmitter, LOG_EVENTS } from '../../utils/events';
import { Stream } from '@elysiajs/stream';

// Re-implementation for robust stream handling
export const logStreamController = new Elysia()
    .get('/reports/:id/logs/stream', ({ params }) => {
        const reportId = parseInt(params.id);

        return new Stream(async (stream) => {
            const sendLogs = async () => {
                const logs = await db
                    .select()
                    .from(reportLogs)
                    .where(eq(reportLogs.reportId, reportId))
                    .orderBy(desc(reportLogs.timestamp));
                
                stream.send(JSON.stringify({ type: 'logs', logs }));
            };

            // Initial send
            await sendLogs();
            stream.send(JSON.stringify({ type: 'connected', reportId }));

            const listener = (id: number) => {
                if (id === reportId) {
                    sendLogs();
                }
            };

            logEventEmitter.on(LOG_EVENTS.NEW_LOG, listener);

            // Wait until the client disconnects
            await stream.wait();

            // Cleanup
            logEventEmitter.off(LOG_EVENTS.NEW_LOG, listener);
        });
    });
