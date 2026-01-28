import { db } from './index';
import { sql } from 'drizzle-orm';

async function reset() {
    console.log('🗑️ Dropping users and report_logs tables to fix sync issues...');
    try {
        await db.execute(sql`DROP TABLE IF EXISTS report_logs CASCADE`);
        await db.execute(sql`DROP TABLE IF EXISTS reports CASCADE`);
        await db.execute(sql`DROP TABLE IF EXISTS users CASCADE`);
        console.log('✅ Tables dropped successfully.');
    } catch (error) {
        console.error('❌ Failed to drop tables:', error);
    }
    process.exit(0);
}

reset();
