import admin from 'firebase-admin';
import { db } from '../db';
import { users, staff } from '../db/schema';
import { eq, inArray } from 'drizzle-orm';
import { readFileSync } from 'fs';

// Initialize Firebase Admin
try {
    let serviceAccount: any;

    // 1. Try loading from Environment Variable (Best for Railway/Production)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    }
    // 2. Try loading from local file (Best for Local Dev)
    else if (require('fs').existsSync('service-account.json')) {
        serviceAccount = JSON.parse(
            readFileSync('service-account.json', 'utf-8')
        );
    }

    if (serviceAccount) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        console.log('🚀 Firebase Admin Initialized for FCM');
    } else {
        console.warn('⚠️ No Firebase credentials found. FCM & Storage will not work.');
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
                androidConfig.notification.channelId = 'lapor_fsm_channel_emergency_v3';
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
        } catch (error: any) {
            console.error('⚠️ FCM Send Error:', error);

            // Handle invalid tokens (delete from DB)
            if (error.code === 'messaging/registration-token-not-registered') {
                console.log(`🧹 Cleaning up invalid FCM token for ${role} ${userId}`);
                const id = parseInt(userId);
                try {
                    if (role === 'user' || role === 'pelapor') {
                        await db.update(users).set({ fcmToken: null }).where(eq(users.id, id));
                    } else {
                        await db.update(staff).set({ fcmToken: null }).where(eq(staff.id, id));
                    }
                    console.log(`✅ Cleaned up invalid FCM token for ${role} ${userId}`);
                } catch (dbError) {
                    console.error(`❌ Failed to clean up FCM token for ${role} ${id}:`, dbError);
                }
            }
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
            androidConfig.notification.channelId = 'lapor_fsm_channel_emergency_v3';
            androidConfig.notification.sound = 'emergency_alert';
        }

        try {
            const response = await admin.messaging().sendEachForMulticast({
                tokens,
                notification: { title, body },
                data,
                android: androidConfig,
            });

            console.log(`✅ FCM Broadcast to ${tokens.length} ${role}s. Success: ${response.successCount}, Failure: ${response.failureCount}`);

            if (response.failureCount > 0) {
                const tokensToRemove: string[] = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
                        tokensToRemove.push(tokens[idx]);
                    }
                });

                if (tokensToRemove.length > 0) {
                    console.log(`🧹 Cleaning up ${tokensToRemove.length} invalid FCM tokens from broadcast...`);
                    try {
                        await db.update(staff)
                            .set({ fcmToken: null })
                            .where(inArray(staff.fcmToken, tokensToRemove));

                        console.log(`✅ Cleaned up ${tokensToRemove.length} invalid tokens from broadcast.`);
                    } catch (dbError) {
                        console.error('❌ Failed to clean up invalid tokens from broadcast:', dbError);
                    }
                }
            }
        } catch (error) {
            console.error('⚠️ FCM Broadcast Error:', error);
        }
    }
};
