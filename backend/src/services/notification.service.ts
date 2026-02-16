import { db } from '../db';
import { notifications, staff, users, reports } from '../db/schema';
import { eq, inArray } from 'drizzle-orm';
import { FCMService } from './fcm.service';
import { logEventEmitter, NOTIFICATION_EVENTS } from '../utils/events';

export class NotificationService {

    /**
     * Helper to determine if a notification should use the emergency type/sound
     */
    private static async resolveType(reportId?: number, currentType: string = 'info'): Promise<'info' | 'success' | 'warning' | 'emergency'> {
        if (currentType === 'emergency') return 'emergency';
        if (!reportId) return currentType as any;

        try {
            const report = await db.select({ isEmergency: reports.isEmergency })
                .from(reports)
                .where(eq(reports.id, reportId))
                .limit(1);

            if (report.length > 0 && report[0].isEmergency) {
                return 'emergency';
            }
        } catch (e) {
            console.error('[NOTIF-SERVICE] Failed to check emergency status', e);
        }

        return currentType as any;
    }

    /**
     * Create a notification for a specific User (Pelapor)
     */
    static async notifyUser(userId: number, title: string, message: string, type: 'info' | 'success' | 'warning' | 'emergency' = 'info', reportId?: number) {
        try {
            const finalType = await this.resolveType(reportId, type);

            await db.insert(notifications).values({
                userId,
                title,
                message,
                type: finalType,
                reportId,
            });

            // Trigger Push Notification (FCM)
            await FCMService.sendToUser(
                userId.toString(),
                'user',
                title,
                message,
                { type: finalType, ...(reportId ? { reportId: reportId.toString() } : {}) }
            );

            logEventEmitter.emit(NOTIFICATION_EVENTS.NEW_NOTIFICATION, {
                type: 'user',
                id: userId,
                data: { title, message, type: finalType, reportId, createdAt: new Date() }
            });

            console.log(`[NOTIF-USER] ID:${userId} - ${title}: ${message} (Report: ${reportId}, Type: ${finalType})`);
        } catch (e) {
            console.error('Failed to notify user', e);
        }
    }

    /**
     * Create a notification for a specific Staff member
     */
    static async notifyStaff(staffId: number, title: string, message: string, type: 'info' | 'success' | 'warning' | 'emergency' = 'info', reportId?: number) {
        try {
            const finalType = await this.resolveType(reportId, type);

            await db.insert(notifications).values({
                staffId,
                title,
                message,
                type: finalType,
                reportId,
            });

            // Trigger Push Notification (FCM)
            await FCMService.sendToUser(
                staffId.toString(),
                'staff',
                title,
                message,
                { type: finalType, ...(reportId ? { reportId: reportId.toString() } : {}) }
            );

            logEventEmitter.emit(NOTIFICATION_EVENTS.NEW_NOTIFICATION, {
                type: 'staff',
                id: staffId,
                data: { title, message, type: finalType, reportId, createdAt: new Date() }
            });

            console.log(`[NOTIF-STAFF] ID:${staffId} - ${title}: ${message} (Report: ${reportId}, Type: ${finalType})`);
        } catch (e) {
            console.error('Failed to notify staff', e);
        }
    }

    /**
     * Broadcast notification to all Staff with a specific role
     */
    static async notifyRole(role: 'supervisor' | 'teknisi' | 'pj_gedung' | 'admin', title: string, message: string, type: 'info' | 'success' | 'warning' | 'emergency' = 'info', reportId?: number) {
        try {
            const finalType = await this.resolveType(reportId, type);
            const roleStaff = await db.select().from(staff).where(eq(staff.role, role));

            if (roleStaff.length === 0) return;

            const newNotifs = roleStaff.map(s => ({
                staffId: s.id,
                title,
                message,
                type: finalType,
                reportId,
            }));

            await db.insert(notifications).values(newNotifs);

            // Trigger Broadcast (FCM)
            await FCMService.broadcastToStaff(
                role,
                title,
                message,
                { type: finalType, ...(reportId ? { reportId: reportId.toString() } : {}) }
            );

            // Emit SSE event for each staff member
            roleStaff.forEach(s => {
                logEventEmitter.emit(NOTIFICATION_EVENTS.NEW_NOTIFICATION, {
                    type: 'staff',
                    id: s.id,
                    data: { title, message, type: finalType, reportId, createdAt: new Date() }
                });
            });

            console.log(`[NOTIF-ROLE] ${role} (${roleStaff.length}) - ${title}: ${message} (Report: ${reportId}, Type: ${finalType})`);
        } catch (e) {
            console.error(`Failed to notify role ${role}`, e);
        }
    }

    /**
     * Broadcast emergency alert to Supervisors and Admins
     */
    static async broadcastEmergency(title: string, message: string, reportId?: number) {
        await this.notifyRole('supervisor', title, message, 'emergency', reportId);
        await this.notifyRole('admin', title, message, 'emergency', reportId);
    }
}


