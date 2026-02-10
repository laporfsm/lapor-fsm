
import { db } from '../src/db';
import { reports, reportLogs } from '../src/db/schema';
import { eq, isNotNull, inArray, sql, count } from 'drizzle-orm';

async function checkIntegrity() {
    console.log("Checking Report Integrity...");

    // 1. Check for Children that are NOT 'recalled' (or archived)
    const nonRecalledChildren = await db.select({
        id: reports.id,
        status: reports.status,
        parentId: reports.parentId
    }).from(reports)
        .where(sql`${reports.parentId} IS NOT NULL AND ${reports.status} != 'recalled'`);

    if (nonRecalledChildren.length > 0) {
        console.log("WARNING: Found merged children that are NOT 'recalled':");
        console.table(nonRecalledChildren);
    } else {
        console.log("OK: All merged children are 'recalled'.");
    }

    // 2. Check for Parents (active reports with children) that are already 'diproses' (Assigned)
    // Find parents first
    const parentsWithChildren = await db.select({
        parentId: reports.parentId,
        childCount: count()
    }).from(reports)
        .where(isNotNull(reports.parentId))
        .groupBy(reports.parentId);

    const parentIds = parentsWithChildren.map(r => r.parentId) as number[];

    if (parentIds.length > 0) {
        const activeParents = await db.select({
            id: reports.id,
            status: reports.status,
            title: reports.title
        }).from(reports)
            .where(inArray(reports.id, parentIds));

        console.log("\nParent Reports Status:");
        console.table(activeParents);

        const assignedParents = activeParents.filter(p => !['pending', 'terverifikasi', 'verifikasi'].includes(p.status || ''));
        if (assignedParents.length > 0) {
            console.log("\nWARNING: Found merged PARENTS that are already processed/assigned/closed:");
            console.table(assignedParents);
        } else {
            console.log("\nOK: All merged PARENTS are still in triage (pending/verified).");
        }
    } else {
        console.log("No merged reports found.");
    }

    process.exit(0);
}

checkIntegrity().catch(console.error);
