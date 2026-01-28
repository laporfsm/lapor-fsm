import { db } from './index';
import { staff, categories, users, reports, reportLogs } from './schema';
import { sql } from 'drizzle-orm';

async function seed() {
    console.log('🚀 Starting deep database seeding...');

    // Clean start to avoid duplicates and ensure clean relationships
    console.log('🧹 Cleaning existing data...');
    await db.delete(reportLogs);
    await db.delete(reports);
    await db.delete(users);
    await db.delete(staff);
    await db.delete(categories);

    // 1. Seed Categories
    console.log('📂 Seeding categories...');
    const cats = await db.insert(categories).values([
        { name: 'Kelistrikan', type: 'non-emergency', icon: 'zap', description: 'Masalah terkait instalasi listrik, lampu, AC, dan stop kontak.' },
        { name: 'Sanitasi', type: 'non-emergency', icon: 'droplet', description: 'Masalah terkait saluran air, kran, toilet, dan kebocoran pipa.' },
        { name: 'Infrastruktur', type: 'non-emergency', icon: 'building', description: 'Gedung, atap, plafon, pintu, jendela, dan fasilitas fisik lainnya.' },
        { name: 'Kebersihan', type: 'non-emergency', icon: 'trash', description: 'Sampah menumpuk, ruangan kotor, atau kebutuhan pembersihan mendesak.' },
        { name: 'Emergency', type: 'emergency', icon: 'alert-triangle', description: 'Kejadian berbahaya seperti kebakaran, pohon tumbang, atau korsleting besar.' },
    ]).returning();

    const catListrik = cats.find(c => c.name === 'Kelistrikan')!;
    const catSanitasi = cats.find(c => c.name === 'Sanitasi')!;
    const catInfra = cats.find(c => c.name === 'Infrastruktur')!;
    const catBersih = cats.find(c => c.name === 'Kebersihan')!;
    const catEmergency = cats.find(c => c.name === 'Emergency')!;

    // 2. Seed Users (Pelapor)
    console.log('👤 Seeding users...');
    const createdUsers = await db.insert(users).values([
        { name: 'Andi Mahasiswa', email: 'andi@student.undip.ac.id', ssoId: 'SSO-001', phone: '081234567890', faculty: 'FSM', department: 'Informatika' },
        { name: 'Siska Mahasiswa', email: 'siska@student.undip.ac.id', ssoId: 'SSO-002', phone: '081234567891', faculty: 'FSM', department: 'Biologi' },
        { name: 'Budi Dosen', email: 'budi@lecturer.undip.ac.id', ssoId: 'SSO-003', phone: '081234567892', faculty: 'FSM', department: 'Fisika' },
    ]).returning();

    // 3. Seed Staff
    console.log('👮 Seeding staff...');
    const pass = await Bun.password.hash('password123');
    const createdStaff = await db.insert(staff).values([
        { name: 'Admin Utama', email: 'admin@laporfsm.com', password: pass, role: 'admin' },
        { name: 'Supervisor Sapto', email: 'supervisor@laporfsm.com', password: pass, role: 'supervisor' },
        { name: 'Teknisi Agus (Listrik)', email: 'agus@laporfsm.com', password: pass, role: 'teknisi', specialization: 'Kelistrikan' },
        { name: 'Teknisi Bambang (Plumbing)', email: 'bambang@laporfsm.com', password: pass, role: 'teknisi', specialization: 'Sanitasi' },
        { name: 'Siti PJ Gedung E', email: 'siti@laporfsm.com', password: pass, role: 'pj_gedung' },
    ]).returning();

    const tAgus = createdStaff.find(s => s.name.includes('Agus'))!;
    const tBambang = createdStaff.find(s => s.name.includes('Bambang'))!;
    const sSapto = createdStaff.find(s => s.role === 'supervisor')!;
    const pSiti = createdStaff.find(s => s.role === 'pj_gedung')!;

    // 4. Seed Reports
    console.log('📝 Seeding realistic reports...');
    
    // -- REPORT 1: PENDING (New)
    const [r1] = await db.insert(reports).values({
        userId: createdUsers[0].id,
        categoryId: catListrik.id,
        title: 'AC Ruang E101 Tidak Dingin',
        description: 'Sudah dinyalakan 1 jam tapi hanya keluar angin. Sangat panas untuk perkuliahan.',
        building: 'Gedung E',
        locationDetail: 'Lantai 1, Ruang Kelas E101',
        isEmergency: false,
        status: 'pending',
        mediaUrls: ['https://images.unsplash.com/photo-1545241047-6083a3684587?w=500'],
    }).returning();

    await db.insert(reportLogs).values({
        reportId: r1.id,
        actorType: 'user',
        actorId: createdUsers[0].id,
        action: 'created',
        toStatus: 'pending',
        notes: 'Laporan baru dikirim',
    });

    // -- REPORT 2: VERIFIED (Waiting for Assignment)
    const [r2] = await db.insert(reports).values({
        userId: createdUsers[1].id,
        categoryId: catBersih.id,
        title: 'Sampah Menumpuk di Kantin',
        description: 'Area sampah di belakang kantin sudah meluap, bau sampai ke area makan.',
        building: 'Kantin FSM',
        locationDetail: 'Area Belakang / Tempat Sampah',
        status: 'terverifikasi',
        verifiedBy: pSiti.id,
        verifiedAt: new Date(Date.now() - 3600000),
    }).returning();

    await db.insert(reportLogs).values([
        { reportId: r2.id, actorType: 'user', actorId: createdUsers[1].id, action: 'created', toStatus: 'pending', notes: 'Bau tidak sedap tercium' },
        { reportId: r2.id, actorType: 'staff', actorId: pSiti.id, action: 'verified', fromStatus: 'pending', toStatus: 'terverifikasi', notes: 'Dikonfirmasi oleh PJ Gedung' },
    ]);

    // -- REPORT 3: IN PROGRESS (Handling)
    const [r3] = await db.insert(reports).values({
        userId: createdUsers[2].id,
        categoryId: catSanitasi.id,
        title: 'Wastafel Mampet di Gedung C',
        description: 'Wastafel di toilet lantai 2 tidak mengalir sama sekali.',
        building: 'Gedung C',
        locationDetail: 'Lantai 2, Toilet Dosen',
        status: 'diproses',
        assignedTo: tBambang.id,
        assignedAt: new Date(Date.now() - 7200000),
        handlingStartedAt: new Date(Date.now() - 3600000),
        mediaUrls: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400'],
    }).returning();

    await db.insert(reportLogs).values([
        { reportId: r3.id, actorType: 'user', actorId: createdUsers[2].id, action: 'created', toStatus: 'pending' },
        { reportId: r3.id, actorType: 'staff', actorId: sSapto.id, action: 'assigned', toStatus: 'penanganan', notes: 'Tolong segera dicek Pak Bambang' },
        { reportId: r3.id, actorType: 'staff', actorId: tBambang.id, action: 'handling', fromStatus: 'penanganan', toStatus: 'diproses', notes: 'Sedang dibongkar pipanya' },
    ]);

    // -- REPORT 4: COMPLETED (Waiting Approval)
    const [r4] = await db.insert(reports).values({
        userId: createdUsers[0].id,
        categoryId: catInfra.id,
        title: 'Gagang Pintu Kelas Lepas',
        description: 'Gagang pintu kelas A202 lepas, mahasiswa kesulitan keluar masuk.',
        building: 'Gedung A',
        locationDetail: 'Lantai 2, Ruang A202',
        status: 'selesai',
        assignedTo: tBambang.id,
        assignedAt: new Date(Date.now() - 172800000),
        handlingStartedAt: new Date(Date.now() - 86400000),
        handlingCompletedAt: new Date(Date.now() - 10800000),
        handlerNotes: 'Sekrup gagang pintu sudah diganti dengan yang lebih kuat.',
        handlerMediaUrls: ['https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=400'],
    }).returning();

    await db.insert(reportLogs).values([
        { reportId: r4.id, actorId: createdUsers[0].id, actorType: 'user', action: 'created', toStatus: 'pending' },
        { reportId: r4.id, actorId: sSapto.id, actorType: 'staff', action: 'assigned', toStatus: 'penanganan' },
        { reportId: r4.id, actorId: tBambang.id, actorType: 'staff', action: 'completed', toStatus: 'selesai', notes: 'Gagang pintu sudah kokoh kembali' },
    ]);

    // -- REPORT 5: EMERGENCY (Immediate Action)
    const [r5] = await db.insert(reports).values({
        userId: createdUsers[1].id,
        categoryId: catEmergency.id,
        title: 'Korsleting Listrik di Kantin',
        description: 'Ada suara ledakan kecil dan bau kabel terbakar di area dapur kantin.',
        building: 'Kantin FSM',
        locationDetail: 'Dapur Utama',
        isEmergency: true,
        status: 'penanganan',
        assignedTo: tAgus.id,
        assignedAt: new Date(),
    }).returning();

    await db.insert(reportLogs).values([
        { reportId: r5.id, actorId: createdUsers[1].id, actorType: 'user', action: 'created', toStatus: 'pending', notes: 'MENDESAK: Ada percikan api!' },
        { reportId: r5.id, actorId: sSapto.id, actorType: 'staff', action: 'assigned', toStatus: 'penanganan', notes: 'DARURAT - Pak Agus merapat sekarang!' },
    ]);

    // -- REPORT 6: APPROVED (History)
    const [r6] = await db.insert(reports).values({
        userId: createdUsers[2].id,
        categoryId: catListrik.id,
        title: 'Lampu Selasar Gedung B Mati',
        description: 'Ada 3 lampu selasar yang mati, sangat gelap di malam hari.',
        building: 'Gedung B',
        locationDetail: 'Lantai dasar, depan Mushola',
        status: 'approved',
        assignedTo: tAgus.id,
        handlingCompletedAt: new Date(Date.now() - 259200000),
        approvedBy: sSapto.id,
        approvedAt: new Date(Date.now() - 172800000),
        handlerNotes: 'Ganti 3 bohlam LED 12 Watt.',
    }).returning();

    await db.insert(reportLogs).values([
        { reportId: r6.id, actorId: createdUsers[2].id, actorType: 'user', action: 'created', toStatus: 'pending' },
        { reportId: r6.id, actorId: tAgus.id, actorType: 'staff', action: 'completed', toStatus: 'selesai' },
        { reportId: r6.id, actorId: sSapto.id, actorType: 'staff', action: 'approved', toStatus: 'approved', notes: 'Sudah terang kembali' },
    ]);

    console.log('✅ Deep seeding completed! 6 realistic reports created with full audit logs.');
}

seed().catch(err => {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
});
