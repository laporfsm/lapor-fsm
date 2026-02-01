import { db } from './index';
import { staff, categories, users, reports, reportLogs, notifications } from './schema';

// Helper to get random item from array
function rnd(arr: any[]) {
    return arr[Math.floor(Math.random() * arr.length)];
}

// Helper to get random date in past X days
function rndDate(daysAgoStart: number, daysAgoEnd: number) {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - daysAgoStart);
    end.setDate(end.getDate() - daysAgoEnd);
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

async function seed() {
    console.log('🚀 Starting COMPREHENSIVE Database Seeding...');
    
    // Hash placeholder
    let pass = "password123_placeholder";
    try {
        pass = await Bun.password.hash('password123');
    } catch (e) {
        console.error('⚠️ Password hash failed, using raw string (dev only).');
    }

    // 1. Clean Data
    try {
        console.log('Step 1: Cleaning data...');
        await db.delete(notifications);
        await db.delete(reportLogs);
        await db.delete(reports);
        await db.delete(users);
        await db.delete(staff);
        await db.delete(categories);
        console.log('✅ Data cleaned.');
    } catch (e) {
        console.error('❌ Failed to clean data (retrying might fix):', e);
        process.exit(1);
    }

    // 2. Categories
    let cats: any[] = [];
    try {
        console.log('Step 2: Seeding categories...');
        cats = await db.insert(categories).values([
            { name: 'Kelistrikan', type: 'non-emergency', icon: 'zap', description: 'Masalah instalasi listrik.' },
            { name: 'Sanitasi', type: 'non-emergency', icon: 'droplet', description: 'Masalah air dan pipa.' },
            { name: 'Infrastruktur', type: 'non-emergency', icon: 'building', description: 'Bangunan dan ruang.' },
            { name: 'Kebersihan', type: 'non-emergency', icon: 'trash', description: 'Sampah dan kotoran.' },
            { name: 'Fasilitas Umum', type: 'non-emergency', icon: 'box', description: 'Fasilitas publik.' },
            { name: 'Internet/IT', type: 'non-emergency', icon: 'wifi', description: 'Jaringan dan IT.' },
            { name: 'Lainnya', type: 'non-emergency', icon: 'help-circle', description: 'Lain-lain.' },
            { name: 'Darurat', type: 'emergency', icon: 'alert-triangle', description: 'Darurat.' },
        ]).returning();
        console.log(`✅ ${cats.length} categories seeded.`);
    } catch (e) {
        console.error('❌ Failed categories:', e);
        process.exit(1);
    }

    // 3. Users
    const createdUsers: any[] = [];
    try {
        console.log('Step 3: Seeding users...');
        const userData = [
            { name: 'Andi Mhs', email: 'andi@student.undip.ac.id', dept: 'Informatika' },
            { name: 'Siska Mhs', email: 'siska@student.undip.ac.id', dept: 'Biologi' },
            { name: 'Budi Dosen', email: 'budi@lecturer.undip.ac.id', dept: 'Fisika' },
        ];

        // Batch insert
        const newUsers = await db.insert(users).values(
            userData.map((u, i) => ({
                name: u.name,
                email: u.email,
                password: pass,
                phone: `0812345678${i}`,
                faculty: 'FSM',
                department: u.dept,
                isVerified: true,
            }))
        ).returning();
        
        createdUsers.push(...newUsers);
        console.log(`✅ ${createdUsers.length} users seeded.`);
    } catch (e) {
        console.error('❌ Failed users:', e);
        process.exit(1);
    }

    // 4. Staff
    const createdStaff: any[] = [];
    const pjs: any[] = [];
    const techs: any[] = [];
    try {
        console.log('Step 4: Seeding staff...');
        
        // Admin
        await db.insert(staff).values({ name: 'Admin', email: 'admin@laporfsm.com', password: pass, role: 'admin' });
        // Supervisor
        await db.insert(staff).values({ name: 'Supervisor', email: 'supervisor@laporfsm.com', password: pass, role: 'supervisor' });

        // Techs
        const techData = [
            { name: 'Agus T', email: 'teknisi@laporfsm.com', spec: 'Kelistrikan' },
            { name: 'Bambang T', email: 'bambang@laporfsm.com', spec: 'Sanitasi' },
            { name: 'Dodi T', email: 'dodi@laporfsm.com', spec: 'Umum' },
        ];
        for (const t of techData) {
            const [nt] = await db.insert(staff).values({ ...t, password: pass, role: 'teknisi' }).returning();
            techs.push(nt);
            createdStaff.push(nt);
        }

        // PJs
        const pjData = [
            { name: 'Siti A', email: 'siti@laporfsm.com', b: 'Gedung A' },
            { name: 'Budi B', email: 'budi_pj@laporfsm.com', b: 'Gedung B' },
            { name: 'Citra C', email: 'citra@laporfsm.com', b: 'Gedung C' },
            { name: 'Deni D', email: 'deni@laporfsm.com', b: 'Gedung D' },
            { name: 'Eko E', email: 'eko@laporfsm.com', b: 'Gedung E' },
            { name: 'Feri F', email: 'feri@laporfsm.com', b: 'Gedung F' },
        ];
        for (const p of pjData) {
            const [np] = await db.insert(staff).values({ 
                name: p.name, email: p.email, password: pass, role: 'pj_gedung', managedBuilding: p.b 
            }).returning();
            pjs.push(np);
            createdStaff.push(np);
        }
        console.log(`✅ Staff seeded.`);
    } catch (e) {
        console.error('❌ Failed staff:', e);
        process.exit(1);
    }

    // 5. Reports
    try {
        console.log('Step 5: Generating reports...');
        const templates = [
            { t: 'AC Panas', c: 'Kelistrikan' }, 
            { t: 'Kran Bocor', c: 'Sanitasi' }, 
            { t: 'Ubin Rusak', c: 'Infrastruktur' },
            { t: 'Sampah Penuh', c: 'Kebersihan' },
            { t: 'Kursi Patah', c: 'Fasilitas Umum' }
        ];
        const statuses = ['pending', 'terverifikasi', 'diproses', 'selesai', 'ditolak'];
        const images = ['https://images.unsplash.com/photo-1545241047-6083a3684587?w=500'];

        for (const pj of pjs) {
            // GUARANTEED FRESH REPORTS to populate dashboard
            // 1. Today
            await db.insert(reports).values({
                userId: rnd(createdUsers).id,
                categoryId: cats[0].id,
                title: 'Laporan Baru Hari Ini',
                description: `Tes laporan hari ini di ${pj.managedBuilding}`,
                building: pj.managedBuilding,
                locationDetail: 'Lobby Utama',
                status: 'pending',
                isEmergency: false,
                mediaUrls: images,
                createdAt: new Date(),
                updatedAt: new Date()
            });

            // 2. 3 Days Ago (Inside Week)
            const threeDaysAgo = new Date();
            threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
            await db.insert(reports).values({
                userId: rnd(createdUsers).id,
                categoryId: cats[1].id,
                title: 'Laporan Minggu Ini',
                description: `Tes laporan minggu ini di ${pj.managedBuilding}`,
                building: pj.managedBuilding,
                locationDetail: 'Koridor Lt 2',
                status: 'terverifikasi',
                isEmergency: false,
                mediaUrls: images,
                createdAt: threeDaysAgo,
                updatedAt: threeDaysAgo
            });

            // 5-8 random reports per building
            const count = 5 + Math.floor(Math.random() * 4);
            for (let i = 0; i < count; i++) {
                const tmpl = rnd(templates);
                const user = rnd(createdUsers);
                const cat = cats.find(c => c.name === tmpl.c) || cats[0];
                const status = rnd(statuses);
                const isEmergency = Math.random() < 0.15;
                const d = rndDate(30, 4); // 4 days ago to 30 days ago (so they don't overlap with guaranteed ones mostly)

                await db.insert(reports).values({
                    userId: user.id,
                    categoryId: cat.id,
                    title: isEmergency ? `[DARURAT] ${tmpl.t}` : tmpl.t,
                    description: `Laporan simulasi di ${pj.managedBuilding}`,
                    building: pj.managedBuilding,
                    locationDetail: 'Lantai 1',
                    status: status,
                    isEmergency: isEmergency,
                    mediaUrls: images,
                    createdAt: d,
                    updatedAt: d
                });
            }
        }
        console.log('✅ Reports generated (with guaranteed fresh data).');
    } catch (e) {
        console.error('❌ Failed reports:', e);
        process.exit(1);
    }

    // 6. Logs (Simplified)
    try {
        console.log('Step 6: Generating basic logs...');
        const allReports = await db.select().from(reports);
        for (const r of allReports) {
            await db.insert(reportLogs).values({
                reportId: r.id,
                actorId: r.userId!.toString(),
                actorName: 'User',
                actorRole: 'pelapor',
                action: 'created',
                toStatus: 'pending',
                timestamp: r.createdAt
            });
        }
        console.log('✅ Logs generated.');

    } catch (e) {
        console.error('❌ Failed logs:', e);
    }

    console.log('🎉 SEED COMPLETED SUCCESSFULLY!');
    process.exit(0);
}

seed();
