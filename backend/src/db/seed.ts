import { db } from './index';
import { categories } from './schema';

// Seed categories based on detail proyek
const seedCategories = async () => {
  console.log('Seeding categories...');
  
  const categoryData = [
    // Emergency
    { name: 'Kecelakaan Lab (K3)', type: 'emergency', icon: 'flask-conical' },
    { name: 'Medis / Kesehatan', type: 'emergency', icon: 'heart-pulse' },
    { name: 'Keamanan (Security)', type: 'emergency', icon: 'shield-alert' },
    { name: 'Bencana / Api', type: 'emergency', icon: 'flame' },
    
    // Non-Emergency: Maintenance
    { name: 'Infrastruktur Kelas', type: 'non-emergency', icon: 'building' },
    { name: 'Kelistrikan', type: 'non-emergency', icon: 'zap' },
    { name: 'Sipil & Bangunan', type: 'non-emergency', icon: 'hard-hat' },
    { name: 'Sanitasi / Air', type: 'non-emergency', icon: 'droplet' },
    
    // Non-Emergency: Kebersihan
    { name: 'Kebersihan Area', type: 'non-emergency', icon: 'trash-2' },
    { name: 'Taman / Outdoor', type: 'non-emergency', icon: 'trees' },
    { name: 'Lain-lain', type: 'non-emergency', icon: 'more-horizontal' },
  ];

  await db.insert(categories).values(categoryData).onConflictDoNothing();
  
  console.log('Categories seeded successfully!');
};

// Run seed
seedCategories()
  .then(() => {
    console.log('Seed completed');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
  });
