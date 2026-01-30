import { db } from '../db';
import { notifications, staff, users } from '../db/schema';
import { eq, inArray } from 'drizzle-orm';

export class NotificationService {

    /**
     * Create a notification for a specific User (Pelapor)
     */
    static async notifyUser(userId: number, title: string, message: string, type: 'info' | 'success' | 'warning' | 'emergency' = 'info', reportId?: number) {
        try {
            await db.insert(notifications).values({
                userId,
                title,
                message,
                type,
                reportId,
            });
            // TODO: Trigger Push Notification (FCM) to User
            console.log(`[NOTIF-USER] ID:${userId} - ${title}: ${message} (Report: ${reportId})`);
        } catch (e) {
            console.error('Failed to notify user', e);
        }
    }

    /**
     * Create a notification for a specific Staff member
     */
    static async notifyStaff(staffId: number, title: string, message: string, type: 'info' | 'success' | 'warning' | 'emergency' = 'info', reportId?: number) {
        try {
            await db.insert(notifications).values({
                staffId,
                title,
                message,
                type,
                reportId,
            });
            // TODO: Trigger Push Notification (FCM) to Staff
            console.log(`[NOTIF-STAFF] ID:${staffId} - ${title}: ${message} (Report: ${reportId})`);
        } catch (e) {
            console.error('Failed to notify staff', e);
        }
    }

    /**
     * Broadcast notification to all Staff with a specific role
     */
    static async notifyRole(role: 'supervisor' | 'teknisi' | 'pj_gedung' | 'admin', title: string, message: string, type: 'info' | 'success' | 'warning' | 'emergency' = 'info', reportId?: number) {
        try {
            const roleStaff = await db.select().from(staff).where(eq(staff.role, role));

            if (roleStaff.length === 0) return;

            const newNotifs = roleStaff.map(s => ({
                staffId: s.id,
                title,
                message,
                type,
                reportId,
            }));

            await db.insert(notifications).values(newNotifs);
            console.log(`[NOTIF-ROLE] ${role} (${roleStaff.length}) - ${title}: ${message} (Report: ${reportId})`);
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
