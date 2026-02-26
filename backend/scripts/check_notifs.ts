import { db } from '../src/db';
import { notifications, staff } from '../src/db/schema';
import { eq, desc } from 'drizzle-orm';

async function checkNotifs() {
  const sups = await db.select().from(staff).where(eq(staff.role, 'supervisor'));
  const supId = sups[0].id;

  const notifs = await db.select().from(notifications)
    .where(eq(notifications.staffId, supId))
    .orderBy(desc(notifications.createdAt));

  console.log('--- Supervisor Notifications ---');
  notifs.forEach(n => {
    console.log(`[${n.id}] TITLE: ${n.title} | REPORT_ID: ${n.reportId} | TYPE: ${n.type} | MSG: ${n.message.substring(0, 30)}...`);
  });

  process.exit(0);
}

checkNotifs().catch(e => { console.error(e); process.exit(1); });
