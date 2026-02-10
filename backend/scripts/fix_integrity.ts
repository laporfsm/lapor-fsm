
import { db } from '../src/db';
import { reports, reportLogs } from '../src/db/schema';
import { eq, isNotNull, inArray, sql, count } from 'drizzle-orm';

async function fixIntegrity() {
    console.log("Fixing Report Integrity...");

    // 1. Force all merged children to be 'recalled'
    const nonRecalledChildren = await db.select({
        id: reports.id
    }).from(reports)
        .where(sql`${reports.parentId} IS NOT NULL AND ${reports.status} != 'recalled'`);

    if (nonRecalledChildren.length > 0) {
        const ids = nonRecalledChildren.map(c => c.id);
        console.log(`Fixing ${ids.length} children status to 'recalled'...`);

        await db.update(reports)
            .set({ status: 'recalled', updatedAt: new Date() })
            .where(inArray(reports.id, ids));

        console.log("Fixed children status.");
    } else {
        console.log("Children integrity OK.");
    }

    // Optional: Warn about parents, but changing their status is risky as it affects technician workflow.
    // Ideally, we just stop new bad merges.

    console.log("Done.");
    process.exit(0);
}

fixIntegrity().catch(console.error);
