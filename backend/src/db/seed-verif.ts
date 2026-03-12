import { db } from './index';
import { users } from './schema';

async function seedVerifUsers() {
  console.log('🌱 Seeding users for verification testing...');

  const testUsers = [
    { name: 'Andi Bachtiar', email: 'andi.b@gmail.com' },
    { name: 'Siti Aminah', email: 'siti.amina@yahoo.com' },
    { name: 'Bambang Pamungkas', email: 'bambang.p@outlook.com' },
    { name: 'Dewi Lestari', email: 'dewi.les@gmail.com' },
    { name: 'Eko Prasetyo', email: 'eko.pra@gmail.com' },
    { name: 'Fajar Nugraha', email: 'fajar.nug@gmail.com' },
    { name: 'Gita Savitri', email: 'gita.sav@gmail.com' },
    { name: 'Hendra Setiawan', email: 'hendra.set@gmail.com' },
    { name: 'Indah Permata', email: 'indah.per@gmail.com' },
    { name: 'Joko Widodo', email: 'jokowi.test@gmail.com' },
  ];

  for (const u of testUsers) {
    try {
      await db.insert(users).values({
        name: u.name,
        email: u.email,
        password: '$argon2id$v=19$m=65536,t=3,p=4$7B/0Gv0+yA7fO0WvSId6fQ$5Qj8n8Uu/pXN1E1w9X1f1A', // password123
        phone: '081234567' + Math.floor(Math.random() * 900 + 100),
        nimNip: '123456',
        isVerified: false,
        isEmailVerified: true, // Set true agar bisa langsung di-verify admin tanpa nunggu email
        isActive: true,
      });
      console.log(`✅ Seeded: ${u.email}`);
    } catch (err) {
      console.log(`❌ Failed (possibly exists): ${u.email}`);
    }
  }

  console.log('✨ Done seeding verif users.');
  process.exit(0);
}

seedVerifUsers();
