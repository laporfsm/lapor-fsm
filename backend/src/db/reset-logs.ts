import { db } from './index';
import { sql } from 'drizzle-orm';

async function reset() {
    console.log('🗑️ Dropping report_logs table to fix sync issues...');
    try {
        await db.execute(sql`DROP TABLE IF EXISTS report_logs CASCADE`);
        console.log('✅ Table dropped successfully.');
    } catch (error) {
        console.error('❌ Failed to drop table:', error);
    }
    process.exit(0);
}

reset();
