import { db } from '../src/db';
import { sql } from 'drizzle-orm';

async function fixSequences() {
    console.log("Synchronizing sequences...");

    const tables = [
        'users',
        'staff',
        'locations',
        'specializations',
        'categories',
        'reports',
        'report_logs',
        'notifications'
    ];

    for (const table of tables) {
        try {
            const seqName = `${table}_id_seq`;
            console.log(`Fixing sequence for ${table}...`);

            // This SQL query sets the sequence to the current MAX(id)
            // If there are no rows, it resets to 1 (using COALESCE)
            await db.execute(sql.raw(`
                SELECT setval('${seqName}', COALESCE((SELECT MAX(id) FROM ${table}), 0) + 1, false)
            `));

            const result = await db.execute(sql.raw(`SELECT last_value FROM ${seqName}`));
            console.log(`  Sequence ${seqName} is now at: ${result[0].last_value}`);
        } catch (e) {
            console.error(`  Failed to fix sequence for ${table}:`, e);
        }
    }

    console.log("Done.");
    process.exit(0);
}

fixSequences().catch(console.error);
