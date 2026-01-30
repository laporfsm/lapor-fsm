import { db } from './index';
import { staff, categories, users, reports, reportLogs, notifications } from './schema';

async function seed() {
    console.log('🚀 Starting EXTENDED database seeding for Testing...');
    try {

        // Clean start
        console.log('🧹 Cleaning existing data...');
        await db.delete(notifications);
        await db.delete(reportLogs);
        await db.delete(reports);
        await db.delete(users);
        await db.delete(staff);
        await db.delete(categories);

        // 1. Seed Categories
        console.log('📂 Seeding categories...');
        const cats = await db.insert(categories).values([
            { name: 'Kelistrikan', type: 'non-emergency', icon: 'zap', description: 'Masalah instalasi listrik, lampu, AC, dan stop kontak.' },
            { name: 'Sanitasi', type: 'non-emergency', icon: 'droplet', description: 'Masalah saluran air, kran, toilet, dan kebocoran pipa.' },
            { name: 'Infrastruktur', type: 'non-emergency', icon: 'building', description: 'Gedung, atap, plafon, pintu, jendela.' },
            { name: 'Kebersihan', type: 'non-emergency', icon: 'trash', description: 'Sampah menumpuk atau ruangan kotor.' },
            { name: 'Fasilitas Umum', type: 'non-emergency', icon: 'box', description: 'Meja, kursi, proyektor, papan tulis.' },
            { name: 'Internet/IT', type: 'non-emergency', icon: 'wifi', description: 'Masalah WiFi, LAN, atau proyektor IT.' },
            { name: 'Lainnya', type: 'non-emergency', icon: 'help-circle', description: 'Laporan kategori lain.' },
            { name: 'Darurat', type: 'emergency', icon: 'alert-triangle', description: 'Kategori khusus laporan darurat.' },
        ]).returning();

        const catListrik = cats.find(c => c.name === 'Kelistrikan')!;
        const catSanitasi = cats.find(c => c.name === 'Sanitasi')!;
        const catInfra = cats.find(c => c.name === 'Infrastruktur')!;
        const catBersih = cats.find(c => c.name === 'Kebersihan')!;
        const catIT = cats.find(c => c.name === 'Internet/IT')!;

        // 2. Seed Users (Pelapor)
        console.log('👤 Seeding users (Pelapor)...');
        const uPass = await Bun.password.hash('password123');
        const createdUsers = await db.insert(users).values([
            { name: 'Andi Mahasiswa', email: 'andi@student.undip.ac.id', password: uPass, phone: '081234567890', faculty: 'FSM', department: 'Informatika', isVerified: true, nimNip: '24060120130001' },
            { name: 'Siska Mahasiswa', email: 'siska@student.undip.ac.id', password: uPass, phone: '081234567891', faculty: 'FSM', department: 'Biologi', isVerified: true, nimNip: '24060120140002' },
            { name: 'Budi Dosen', email: 'budi@lecturer.undip.ac.id', password: uPass, phone: '081234567892', faculty: 'FSM', department: 'Fisika', isVerified: true, nimNip: '198001012005011001' },
        ]).returning();

        // 3. Seed Staff (Multiple Roles)
        console.log('👮 Seeding staff members...');
        const pass = await Bun.password.hash('password123');
        const createdStaff = await db.insert(staff).values([
            { name: 'Admin Utama', email: 'admin@laporfsm.com', password: pass, role: 'admin' },
            { name: 'Sapto Supervisor', email: 'supervisor@laporfsm.com', password: pass, role: 'supervisor' },
            { name: 'Agus Teknisi', email: 'teknisi@laporfsm.com', password: pass, role: 'teknisi', specialization: 'Kelistrikan' },
            { name: 'Bambang Teknisi', email: 'bambang@laporfsm.com', password: pass, role: 'teknisi', specialization: 'Sanitasi' },
            { name: 'Dodi Teknisi', email: 'dodi@laporfsm.com', password: pass, role: 'teknisi', specialization: 'Umum' },
            { name: 'Siti PJ Gedung A', email: 'siti@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Budi PJ Gedung B', email: 'budi_pj@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Citra PJ Gedung C', email: 'citra@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Deni PJ Gedung D', email: 'deni@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Eko PJ Gedung E', email: 'eko@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Feri PJ Gedung F', email: 'feri@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Gita PJ Lab Terpadu', email: 'gita@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Hadi PJ Perpustakaan', email: 'hadi@laporfsm.com', password: pass, role: 'pj_gedung' },
            { name: 'Indra PJ Dekanat', email: 'indra@laporfsm.com', password: pass, role: 'pj_gedung' },
        ]).returning();

        const tAgus = createdStaff.find(s => s.email === 'teknisi@laporfsm.com')!;
        const tBambang = createdStaff.find(s => s.email === 'bambang@laporfsm.com')!;
        const tDodi = createdStaff.find(s => s.email === 'dodi@laporfsm.com')!;
        const sSapto = createdStaff.find(s => s.role === 'supervisor')!;
        const pSiti = createdStaff.find(s => s.email === 'siti@laporfsm.com')!;

        // 4. Seed Reports (Diverse Scenarios)
        console.log('📝 Seeding 15+ diverse reports...');

        // -- GEDUNG E (Area Eko)
        const [r1] = await db.insert(reports).values({
            userId: createdUsers[0].id,
            categoryId: catListrik.id,
            title: 'AC Mati di E101',
            description: 'AC tidak dingin sama sekali sejak pagi.',
            building: 'Gedung E',
            locationDetail: 'Ruang Kelas E101',
            status: 'pending',
            mediaUrls: ['https://images.unsplash.com/photo-1545241047-6083a3684587?w=500'],
        }).returning();

        // -- GEDUNG A (Area Siti)
        const [r2] = await db.insert(reports).values({
            userId: createdUsers[1].id,
            categoryId: catBersih.id,
            title: 'Sampah Menumpuk di Koridor',
            description: 'Sampah sudah 2 hari tidak diangkat.',
            building: 'Gedung A',
            locationDetail: 'Lantai 2, depan Lift',
            status: 'terverifikasi',
            verifiedBy: pSiti.id,
            verifiedAt: new Date(Date.now() - 3600000),
        }).returning();

        // -- GEDUNG C (InProgress)
        const [r3] = await db.insert(reports).values({
            userId: createdUsers[2].id,
            categoryId: catSanitasi.id,
            title: 'Kran Air Patah',
            description: 'Air mengalir terus di wastafel.',
            building: 'Gedung C',
            locationDetail: 'Toilet Dosen Lt 1',
            status: 'penanganan',
            assignedTo: tBambang.id,
            assignedAt: new Date(Date.now() - 7200000),
            handlingStartedAt: new Date(Date.now() - 3600000),
        }).returning();

        // -- LAB KOMPUTER (On Hold)
        const [r4] = await db.insert(reports).values({
            userId: createdUsers[0].id,
            categoryId: catIT.id,
            title: 'WiFi Lab MIPA 1 Mati',
            description: 'Satu ruangan tidak bisa akses internet.',
            building: 'Laboratorium',
            locationDetail: 'Lab Komputer MIPA 1',
            status: 'onHold',
            assignedTo: tAgus.id,
            assignedAt: new Date(Date.now() - 86400000),
            handlingStartedAt: new Date(Date.now() - 43200000),
            pausedAt: new Date(Date.now() - 3600000),
            holdReason: 'Menunggu perangkat pengganti dari gudang.',
        }).returning();

        // -- RECALLED (Needs revision)
        const [r5] = await db.insert(reports).values({
            userId: createdUsers[1].id,
            categoryId: catInfra.id,
            title: 'Engsel Pintu Rusak',
            description: 'Pintu tidak bisa ditutup rapat karena engselnya bengkok.',
            building: 'Gedung B',
            status: 'recalled',
            assignedTo: tDodi.id,
            updatedAt: new Date(),
        }).returning();

        // -- EMERGENCY (High Priority)
        const [r6] = await db.insert(reports).values({
            userId: createdUsers[2].id,
            categoryId: catListrik.id,
            title: 'Korsleting Panel Listrik',
            description: 'Ada bau terbakar dari boks panel.',
            building: 'Gedung D',
            isEmergency: true,
            status: 'diproses',
            assignedTo: tAgus.id,
            assignedAt: new Date(),
        }).returning();

        // -- COMPLETED (Pending Approval)
        const [r7] = await db.insert(reports).values({
            userId: createdUsers[0].id,
            categoryId: catBersih.id,
            title: 'Genangan Air di Lobby',
            description: 'Ada genangan air di lobby depan pintu masuk, sepertinya dari atap yang bocor.',
            building: 'Gedung A',
            status: 'selesai',
            assignedTo: tBambang.id,
            handlingCompletedAt: new Date(Date.now() - 1800000),
            handlerNotes: 'Atap sudah ditambal sementara.',
        }).returning();

        // -- HISTORY (Approved)
        await db.insert(reports).values([
            {
                userId: createdUsers[1].id,
                categoryId: catListrik.id,
                title: 'Lampu Kelas Mati',
                description: 'Lampu di bagian belakang kelas mati 2 baris.',
                building: 'Gedung B',
                status: 'approved',
                assignedTo: tAgus.id,
                approvedBy: sSapto.id,
                approvedAt: new Date(Date.now() - 86400000),
            },
            {
                userId: createdUsers[2].id,
                categoryId: catSanitasi.id,
                title: 'Toilet Mampet',
                description: 'Saluran pembuangan toilet lantai 1 mampet.',
                building: 'Gedung C',
                status: 'approved',
                assignedTo: tBambang.id,
                approvedBy: sSapto.id,
                approvedAt: new Date(Date.now() - 172800000),
            }
        ]);

        // 4.1. Seed Reports for Grouping Testing (AC Bocor - Gedung E)
        console.log('📦 Seeding grouping candidate reports...');
        await db.insert(reports).values([
            {
                userId: createdUsers[0].id,
                categoryId: catListrik.id,
                title: 'AC Bocor di E102',
                description: 'AC meneteskan air cukup deras, mengganggu kuliah.',
                building: 'Gedung E',
                locationDetail: 'Ruang E102',
                status: 'pending',
                mediaUrls: ['https://images.unsplash.com/photo-1621905251189-08b95d50c04f?w=500'],
                createdAt: new Date(Date.now() - 3600000), // 1 hour ago
            },
            {
                userId: createdUsers[1].id,
                categoryId: catListrik.id,
                title: 'AC Bocor di E103',
                description: 'AC bocor membasahi lantai.',
                building: 'Gedung E',
                locationDetail: 'Ruang E103',
                status: 'pending', // Pending so Supervisor can group them
                mediaUrls: ['https://images.unsplash.com/photo-1621905251189-08b95d50c04f?w=500'],
                createdAt: new Date(Date.now() - 3500000), // ~58 mins ago
            },
            {
                userId: createdUsers[0].id,
                categoryId: catListrik.id,
                title: 'AC Bocor di E104',
                description: 'Tetesan air AC merusak plafon.',
                building: 'Gedung E',
                locationDetail: 'Ruang E104',
                status: 'pending',
                mediaUrls: ['https://images.unsplash.com/photo-1621905251189-08b95d50c04f?w=500'],
                createdAt: new Date(Date.now() - 3400000), // ~56 mins ago
            },
        ]);

        // 5. Seed Logs (Make timeline rich)
        console.log('📜 Seeding audit logs for all reports...');
        const allReports = await db.select().from(reports);
        console.log(`Found ${allReports.length} reports to process.`);

        for (const r of allReports) {
            // Log Creation
            await db.insert(reportLogs).values({
                reportId: r.id,
                actorId: r.userId?.toString() || "0",
                actorName: createdUsers.find(u => u.id === r.userId)?.name || "Reporter",
                actorRole: 'pelapor',
                action: 'created',
                toStatus: 'pending',
                reason: 'Laporan baru dikirim melalui aplikasi.',
                timestamp: new Date(r.createdAt!.getTime() - 1000),
            });

            if (r.status !== 'pending') {
                // Log Verification
                await db.insert(reportLogs).values({
                    reportId: r.id,
                    actorId: pSiti.id.toString(),
                    actorName: pSiti.name,
                    actorRole: 'pj_gedung',
                    action: 'verified',
                    fromStatus: 'pending',
                    toStatus: 'terverifikasi',
                    reason: 'Sudah diinspeksi di lapangan.',
                    timestamp: new Date(r.createdAt!.getTime() + 600000),
                });
            }

            if (r.assignedTo) {
                // Log Assignment
                await db.insert(reportLogs).values({
                    reportId: r.id,
                    actorId: sSapto.id.toString(),
                    actorName: sSapto.name,
                    actorRole: 'supervisor',
                    action: 'handling',
                    fromStatus: 'terverifikasi',
                    toStatus: 'diproses',
                    reason: 'Teknisi ditugaskan.',
                    timestamp: new Date(r.createdAt!.getTime() + 1200000),
                });
            }

            if (r.status === 'onHold' && r.holdReason) {
                await db.insert(reportLogs).values({
                    reportId: r.id,
                    actorId: r.assignedTo!.toString(),
                    actorName: createdStaff.find(s => s.id === r.assignedTo)?.name || "Teknisi",
                    actorRole: 'teknisi',
                    action: 'paused',
                    fromStatus: 'penanganan',
                    toStatus: 'onHold',
                    reason: r.holdReason,
                });
            }
        }

        console.log('✅ EXTENDED seeding completed! Use credentials below for testing.');
        console.log('------------------------------------------------------------');
        console.log('PELAPOR (Login with Email & "password123"):');
        console.log(' - andi@student.undip.ac.id');
        console.log(' - siska@student.undip.ac.id');
        console.log(' - budi@lecturer.undip.ac.id');
        console.log('STAFF (Login with Email & "password123"):');
        console.log(' - Admin: admin@laporfsm.com');
        console.log(' - Supervisor: supervisor@laporfsm.com');
        console.log(' - Teknisi: teknisi@laporfsm.com (Agus)');
        console.log(' - PJ Gedung: siti@laporfsm.com (Gedung A)');
        console.log(' - PJ Gedung: eko@laporfsm.com (Gedung E)');
        console.log(' - ... sisa akun PJ: budi_pj (B), citra (C), deni (D), feri (F), gita (Lab), hadi (Perpus), indra (Dekanat) @laporfsm.com');
    } catch (err) {
        console.error('❌ SEED ERROR:', err);
        throw err;
    }
}

seed().catch(err => {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
});
