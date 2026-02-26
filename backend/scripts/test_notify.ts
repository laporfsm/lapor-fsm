import { db } from '../src/db';
import { notifications } from '../src/db/schema';
import { NotificationService } from '../src/services/notification.service';
import { eq, desc } from 'drizzle-orm';

async function test() {
    await NotificationService.notifyRole('supervisor', 'Laporan Terverifikasi TEST', 'Testing ID passthrough', 'info', 9999);
    console.log('Notification sent.');

    const notifs = await db.select().from(notifications)
        .where(eq(notifications.title, 'Laporan Terverifikasi TEST'))
        .orderBy(desc(notifications.createdAt));

    console.log('Result in DB:', notifs.map(n => ({ id: n.id, title: n.title, reportId: n.reportId })));
    process.exit(0);
}

test().catch(e => { console.error(e); process.exit(1); });
