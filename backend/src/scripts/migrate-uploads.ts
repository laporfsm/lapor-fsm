/**
 * Migration Script: Upload local files to Supabase Storage & update DB URLs
 * 
 * Run from backend folder: bun run src/scripts/migrate-uploads.ts
 */

import { readdirSync, readFileSync } from 'fs';
import { join, extname } from 'path';
import { db } from '../db';
import { reports, reportLogs } from '../db/schema';
import { supabase } from '../lib/supabase';
import { sql } from 'drizzle-orm';

const UPLOAD_DIR = './uploads';
const BUCKET_NAME = 'media';

const IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
const VIDEO_EXTENSIONS = ['.mp4', '.mov', '.avi', '.mpeg'];

function getMimeType(ext: string): string {
    const mimeMap: Record<string, string> = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.webp': 'image/webp',
        '.gif': 'image/gif',
        '.mp4': 'video/mp4',
        '.mov': 'video/quicktime',
        '.avi': 'video/x-msvideo',
        '.mpeg': 'video/mpeg',
    };
    return mimeMap[ext] || 'application/octet-stream';
}

async function uploadFilesToSupabase(): Promise<Map<string, string>> {
    const urlMap = new Map<string, string>(); // old filename -> new supabase URL

    let files: string[];
    try {
        files = readdirSync(UPLOAD_DIR);
    } catch {
        console.error(`❌ Folder '${UPLOAD_DIR}' tidak ditemukan. Pastikan script dijalankan dari folder backend.`);
        process.exit(1);
    }

    console.log(`📂 Ditemukan ${files.length} file di ${UPLOAD_DIR}`);

    let successCount = 0;
    let failCount = 0;

    for (const filename of files) {
        const ext = extname(filename).toLowerCase();
        const isImage = IMAGE_EXTENSIONS.includes(ext);
        const isVideo = VIDEO_EXTENSIONS.includes(ext);

        if (!isImage && !isVideo) {
            console.warn(`⏭️  Skip (unknown type): ${filename}`);
            continue;
        }

        const folder = isImage ? 'images' : 'videos';
        const storagePath = `${folder}/${filename}`;
        const filepath = join(UPLOAD_DIR, filename);

        try {
            const fileBuffer = readFileSync(filepath);
            const contentType = getMimeType(ext);

            const { data, error } = await supabase.storage
                .from(BUCKET_NAME)
                .upload(storagePath, fileBuffer, {
                    contentType,
                    upsert: true, // overwrite if exists
                });

            if (error) {
                throw error;
            }

            // Get public URL
            const { data: { publicUrl } } = supabase.storage
                .from(BUCKET_NAME)
                .getPublicUrl(storagePath);

            urlMap.set(filename, publicUrl);
            successCount++;
            console.log(`✅ [${successCount}/${files.length}] ${filename} → ${publicUrl}`);
        } catch (err) {
            failCount++;
            console.error(`❌ Gagal upload ${filename}:`, err);
        }
    }

    console.log(`\n📊 Hasil upload: ${successCount} sukses, ${failCount} gagal, dari ${files.length} total`);
    return urlMap;
}

async function updateDatabaseUrls(urlMap: Map<string, string>) {
    console.log('\n🔄 Memulai update URL di database...');

    // Build the replacement mapping for SQL
    // We need to replace any URL containing the filename with the new Supabase URL
    // Patterns to match: http://localhost:3000/uploads/FILENAME or similar

    // 1. Update reports.mediaUrls
    const allReports = await db.select({
        id: reports.id,
        mediaUrls: reports.mediaUrls,
        handlerMediaUrls: reports.handlerMediaUrls,
        holdPhoto: reports.holdPhoto,
    }).from(reports);

    let updatedReports = 0;
    for (const report of allReports) {
        let changed = false;

        // Update mediaUrls (jsonb array)
        const mediaUrls = (report.mediaUrls as string[]) || [];
        const newMediaUrls = mediaUrls.map(url => replaceUrl(url, urlMap));
        if (JSON.stringify(mediaUrls) !== JSON.stringify(newMediaUrls)) changed = true;

        // Update handlerMediaUrls (jsonb array)
        const handlerMediaUrls = (report.handlerMediaUrls as string[]) || [];
        const newHandlerMediaUrls = handlerMediaUrls.map(url => replaceUrl(url, urlMap));
        if (JSON.stringify(handlerMediaUrls) !== JSON.stringify(newHandlerMediaUrls)) changed = true;

        // Update holdPhoto (text)
        let newHoldPhoto = report.holdPhoto;
        if (report.holdPhoto) {
            newHoldPhoto = replaceUrl(report.holdPhoto, urlMap);
            if (newHoldPhoto !== report.holdPhoto) changed = true;
        }

        if (changed) {
            await db.update(reports)
                .set({
                    mediaUrls: newMediaUrls,
                    handlerMediaUrls: newHandlerMediaUrls,
                    holdPhoto: newHoldPhoto,
                })
                .where(sql`${reports.id} = ${report.id}`);
            updatedReports++;
        }
    }
    console.log(`📝 Reports: ${updatedReports} rows updated`);

    // 2. Update reportLogs.mediaUrls
    const allLogs = await db.select({
        id: reportLogs.id,
        mediaUrls: reportLogs.mediaUrls,
    }).from(reportLogs);

    let updatedLogs = 0;
    for (const log of allLogs) {
        const mediaUrls = (log.mediaUrls as string[]) || [];
        const newMediaUrls = mediaUrls.map(url => replaceUrl(url, urlMap));

        if (JSON.stringify(mediaUrls) !== JSON.stringify(newMediaUrls)) {
            await db.update(reportLogs)
                .set({ mediaUrls: newMediaUrls })
                .where(sql`${reportLogs.id} = ${log.id}`);
            updatedLogs++;
        }
    }
    console.log(`📝 Report Logs: ${updatedLogs} rows updated`);
}

function replaceUrl(url: string, urlMap: Map<string, string>): string {
    // Extract filename from URL (last segment after /)
    for (const [filename, newUrl] of urlMap) {
        if (url.includes(filename)) {
            return newUrl;
        }
    }
    return url; // Return original if no match found
}

// --- Main ---
async function main() {
    console.log('🚀 Starting migration: Local uploads → Supabase Storage\n');

    // Step 1: Upload files
    const urlMap = await uploadFilesToSupabase();

    if (urlMap.size === 0) {
        console.log('⚠️  Tidak ada file yang berhasil di-upload. Proses dihentikan.');
        process.exit(0);
    }

    // Step 2: Update database
    await updateDatabaseUrls(urlMap);

    console.log('\n🎉 Migrasi selesai!');
    process.exit(0);
}

main().catch((err) => {
    console.error('❌ Migration failed:', err);
    process.exit(1);
});
