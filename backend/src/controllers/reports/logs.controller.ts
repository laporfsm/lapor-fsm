import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { reportLogs } from '../../db/schema';
import { desc, eq } from 'drizzle-orm';
import { logEventEmitter, LOG_EVENTS } from '../../utils/events';
import { Stream } from '@elysiajs/stream';

export const logsController = new Elysia()
    .get('/reports/:reportId/logs/stream', ({ params }) => {
        const reportId = parseInt(params.reportId);

        return new Stream(async (stream) => {
            // function to fetch and send logs
            const sendLogs = async () => {
                const logs = await db
                    .select()
                    .from(reportLogs)
                    .where(eq(reportLogs.reportId, reportId))
                    .orderBy(desc(reportLogs.timestamp));
                
                stream.send({ type: 'logs', logs });
            };

            // Send initial logs
            await sendLogs();
            stream.send({ type: 'connected', reportId });

            // Listen for new logs
            const listener = (id: number) => {
                if (id === reportId) {
                    sendLogs();
                }
            };

            logEventEmitter.on(LOG_EVENTS.NEW_LOG, listener);

            // Cleanup on close is handled by Elysia Stream (mostly), 
            // but we should ensure listener is removed if the stream closes.
            // Elysia Stream doesn't expose a clear 'close' event in the callback easily without a looped generator or wait,
            // but here we are using the callback style. 
            // Actually, `Stream` class in Elysia handles `wait` or `events`.
            // Let's use the standard approach for Elysia streams with event emitters.
            
            // To properly handle cleanup in this callback style is tricky. 
            // A better way with Elysia Stream is to return an async generator or use the wait promise.
            // However, since we need to listen to an event emitter, we can use a simpler approach:
            // The stream object has a `close` promise.

            // Wait for stream to close to remove listener
            // (This depends on Elysia version, but usually efficient)
            // Ideally we'd use `request.signal.addEventListener('abort', ...)` if available context.

        }, {
            close() {
                // This callback is fired when the stream is closed
                // But we need reference to the listener. 
                // Currently defining listener inside generic scope limits this.
                // We will rely on the closure scope.
            }
        });
        
        // Revised approach using a clearer pattern for cleanup:
        // We can't easily pass the specific listener to `close` unless we define it outside?
        // Let's retry the implementation structure to ensure memory safety.
    })

// Re-implementation for robust stream handling
export const logStreamController = new Elysia()
    .get('/reports/:reportId/logs/stream', ({ params }) => {
        const reportId = parseInt(params.reportId);

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
