import admin from 'firebase-admin';
import { db } from '../db';
import { users, staff } from '../db/schema';
import { eq } from 'drizzle-orm';
import { readFileSync } from 'fs';

// Initialize Firebase Admin
try {
    // Check if file exists to prevent crash in dev environments without the key
    if (require('fs').existsSync('service-account.json')) {
        const serviceAccount = JSON.parse(
            readFileSync('service-account.json', 'utf-8')
        );

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        console.log('🔥 Firebase Admin Initialized');
    } else {
        console.warn('⚠️ service-account.json not found. FCM will not be initialized.');
    }
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error);
}

export const FCMService = {
    async sendToUser(
        userId: string,
        role: string, // 'user' (pelapor) or 'staff' (teknisi, supervisor, etc)
        title: string,
        body: string,
        data: Record<string, string> = {}
    ) {
        if (admin.apps.length === 0) return;

        try {
            let token: string | null | undefined = null;
            const id = parseInt(userId);

            if (role === 'user' || role === 'pelapor') {
                const user = await db.select().from(users).where(eq(users.id, id));
                token = user[0]?.fcmToken;
            } else {
                const member = await db.select().from(staff).where(eq(staff.id, id));
                token = member[0]?.fcmToken;
            }

            if (!token) return;

            const androidConfig: any = {
                priority: 'high',
                notification: {
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                }
            };

            if (data.type === 'emergency') {
                androidConfig.notification.channelId = 'lapor_fsm_channel_emergency_v2';
                androidConfig.notification.sound = 'emergency_alert';
            }

            await admin.messaging().send({
                token: token,
                notification: {
                    title,
                    body,
                },
                data: data,
                android: androidConfig,
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                        }
                    }
                }
            });
            console.log(`✅ FCM sent to ${role} ${userId}: ${title}`);
        } catch (error) {
            console.error('⚠️ FCM Send Error:', error);
            // Optional: Handle invalid tokens here (delete from DB)
        }
    },

    async broadcastToStaff(
        role: 'teknisi' | 'supervisor' | 'pj_gedung' | 'admin',
        title: string,
        body: string,
        data: Record<string, string> = {}
    ) {
        if (admin.apps.length === 0) return;

        const targetStaff = await db
            .select()
            .from(staff)
            .where(eq(staff.role, role));

        const tokens = targetStaff
            .map(s => s.fcmToken)
            .filter((t): t is string => !!t);

        if (tokens.length === 0) return;

        const androidConfig: any = {
            priority: 'high',
            notification: {
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            }
        };

        if (data.type === 'emergency') {
            androidConfig.notification.channelId = 'lapor_fsm_channel_emergency_v2';
            androidConfig.notification.sound = 'emergency_alert';
        }

        try {
            await admin.messaging().sendEachForMulticast({
                tokens,
                notification: { title, body },
                data,
                android: androidConfig,
            });
            console.log(`✅ FCM Broadcast to ${tokens.length} ${role}s`);
        } catch (error) {
            console.error('⚠️ FCM Broadcast Error:', error);
        }
    }
};
