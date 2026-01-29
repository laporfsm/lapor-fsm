<p align="center">
  <img src="mobile/assets/images/logo.png" alt="Lapor FSM Logo" width="120"/>
</p>

<h1 align="center">Lapor FSM!</h1>

<p align="center">
  <strong>Sistem Pelaporan Insiden & Fasilitas untuk Civitas Akademika FSM Undip</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Bun-Runtime-orange?logo=bun" alt="Bun"/>
  <img src="https://img.shields.io/badge/ElysiaJS-Backend-purple" alt="ElysiaJS"/>
  <img src="https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql" alt="PostgreSQL"/>
</p>

---

## 📋 Deskripsi

**Lapor FSM!** adalah platform pelaporan berbasis mobile yang dirancang untuk civitas akademika FSM (Fakultas Sains dan Matematika) Universitas Diponegoro. Aplikasi ini memungkinkan mahasiswa dan dosen untuk melaporkan insiden darurat atau kerusakan fasilitas dengan fitur pelacakan lokasi real-time.

### ✨ Fitur Utama

#### 🚨 Pelaporan Insiden
| Fitur | Deskripsi |
|-------|-----------|
| **Panic Button** | Tombol darurat sekali tekan untuk pelaporan cepat dengan pengiriman lokasi otomatis |
| **Auto-Location Tagging** | GPS presisi tinggi untuk menentukan koordinat lokasi kejadian secara otomatis |
| **Bukti Multimedia** | Wajib menyertakan foto/video langsung dari lokasi kejadian sebagai bukti valid |
| **Pemilihan Gedung** | Pilih gedung spesifik tempat kejadian untuk akurasi lokasi |
| **Kategori Insiden** | Klasifikasi laporan: Emergency (K3, Medis, Keamanan, Bencana) & Non-Emergency (Maintenance, Kebersihan) |

#### 🔴 Real-time Tracking
| Fitur | Deskripsi |
|-------|-----------|
| **Emergency Live Tracking** | Streaming lokasi pelapor setiap detik via WebSockets untuk kondisi darurat |
| **Peta Interaktif** | Teknisi & Supervisor dapat memantau pergerakan pelapor darurat secara real-time tanpa refresh halaman |
| **Status Tracking** | Pelapor dapat memantau setiap tahap penanganan laporan mereka secara transparan |

#### 🛠️ Penanganan Laporan
| Fitur | Deskripsi |
|-------|-----------|
| **Lifecycle Management** | Alur status: Pending → Verifikasi → Penanganan → Selesai (atau Penanganan Ulang) |
| **Validasi Teknisi** | Teknisi memvalidasi laporan masuk dan mengelola status lifecycle |
| **Bukti Penanganan** | Teknisi wajib upload foto/video bukti saat menyelesaikan penanganan |
| **Recall Teknisi** | Supervisor dapat memanggil kembali teknisi jika penanganan dinilai belum tuntas |

#### 📊 Monitoring & Evaluasi
| Fitur | Deskripsi |
|-------|-----------|
| **Timer Durasi** | Penghitungan waktu otomatis dari laporan masuk hingga selesai untuk evaluasi kinerja |
| **Dashboard Analitik** | Statistik dan histori laporan untuk evaluasi fakultas jangka panjang |
| **Public Feed** | Transparansi laporan aktif dengan fitur filter berdasarkan kategori dan lokasi |
| **Arsip Laporan** | Riwayat laporan keseluruhan untuk memantau performa pelayanan |

#### 📄 Export & Administrasi
| Fitur | Deskripsi |
|-------|-----------|
| **Export Excel** | Unduh data laporan untuk keperluan pengolahan data lebih lanjut |
| **Export PDF** | Cetak laporan dalam format dokumen resmi |
| **Manajemen Akun** | Admin mengelola akun pengguna, hak akses, dan kategori laporan |
| **Verifikasi Registrasi** | Proses verifikasi untuk user non-UNDIP dengan validasi kartu identitas |

---

## 🏗️ Arsitektur Proyek

Repositori ini menggunakan arsitektur **Monorepo** yang berisi kode untuk Mobile Apps dan Backend API.

```text
lapor-fsm/
├── 📱 mobile/          # Aplikasi Flutter (Android/iOS)
│   ├── lib/
│   │   ├── core/       # Router, Services, Theme, Widgets, Utils, Models
│   │   ├── features/   # Fitur per Role
│   │   │   ├── admin/         # Panel Admin & Manajemen
│   │   │   ├── auth/          # Autentikasi Pelapor & Staff
│   │   │   ├── notification/  # Sistem Notifikasi
│   │   │   ├── pelapor/       # Fitur Pelapor & Feed Umum
│   │   │   ├── pj_gedung/     # Dashboard & Verifikasi Gedung
│   │   │   ├── report_common/ # Komponen Laporan Bersama
│   │   │   ├── supervisor/    # Dashboard & Review Supervisor
│   │   │   └── teknisi/       # Panel Penanganan Teknisi
│   │   └── main.dart
│   └── assets/         # Logo, Icon, & Gambar
│
└── 🖥️ backend/         # Server ElysiaJS + Bun (API)
    ├── src/
    │   ├── controllers/    # API Controllers
    │   │   ├── admin/
    │   │   ├── reporter/
    │   │   ├── staff/
    │   │   ├── supervisor/
    │   │   ├── technician/
    │   │   ├── auth.controller.ts
    │   │   └── notification.controller.ts
    │   ├── db/             # Schema & Seeding
    │   └── uploads/        # Media Storage
```

---

## 👥 Role (Peran Pengguna)

| Role | Deskripsi | Fitur Utama |
|------|-----------|-------------|
| **Pelapor** | Mahasiswa / Dosen FSM | Kirim laporan, lacak status real-time, pantau public feed |
| **Teknisi** | Petugas Lapangan | Terima tugas, update progress penanganan, upload bukti selesai |
| **PJ Gedung** | Penanggung Jawab Area | Verifikasi laporan awal, pantau statistik gedung spesifik |
| **Supervisor** | Manajer & Verifikator | Evaluasi kinerja teknisi, ulas laporan ditolak, ekspor data |
| **Admin** | Pengelola Sistem | Manajemen user/staf, konfigurasi kategori, audit log sistem |

---

## 📊 Kategori Laporan

### 🔴 Emergency
- **Darurat**: Kategori khusus untuk respon cepat (Kebakaran, Medis, K3, Keamanan).

### 🟢 Non-Emergency
- **Kelistrikan**: Lampu, AC, Stop kontak, dsb.
- **Sanitasi**: Kran bocor, wastafel, toilet mampet.
- **Infrastruktur**: Kerusakan bangunan, atap, plafon, pintu.
- **Kebersihan**: Sampah menumpuk, ruangan kotor.
- **Fasilitas Umum**: Meja, kursi, proyektor.
- **Internet/IT**: Masalah WiFi, LAN, Proyektor IT.
- **Lainnya**: Laporan di luar kategori utama.

---

## 🛠️ Teknologi

### Frontend (Mobile)
| Teknologi | Versi | Kegunaan |
|-----------|-------|----------|
| Flutter | ^3.9.2 | SDK Utama |
| Riverpod | ^3.1.0 | State management |
| Go Router | ^17.0.1 | Navigation & routing |
| Geolocator | ^14.0.2 | GPS & location services |
| Flutter Map | ^8.2.2 | Interactive map preview |
| Dio | ^5.9.0 | HTTP client |
| Image Picker | ^1.2.1 | Camera & gallery access |
| Lucide Icons | ^0.257.0 | Icon system |
| FL Chart | ^1.1.1 | Statistik & Grafik |

### Backend
| Teknologi | Versi | Kegunaan |
|-----------|-------|----------|
| ElysiaJS | ^1.4.x | Web framework (WebSocket support) |
| Bun | ^1.3.x | JS/TS runtime & package manager |
| Drizzle ORM | ^0.45.1 | Database ORM |
| PostgreSQL | ^3.4.8 | Database driver (node-postgres/postgres.js) |

---

## 🎨 UI Design System

Untuk memastikan konsistensi visual di seluruh role, proyek ini menggunakan sekumpulan widget kustom yang terstandarisasi:

- **Base Templates**: `mobile/lib/core/widgets/base_templates.dart` melayani pembuatan halaman bantuan (`BaseHelpPage`) yang seragam.
- **Statistics Widgets**: `mobile/lib/core/widgets/statistics_widgets.dart` menyediakan komponen visualisasi data (Cards, Bar Charts, Trend Info) yang kohesif.
- **Profile Widgets**: `mobile/lib/core/widgets/profile_widgets.dart` mengatur tata letak informasi profil dan menu navigasi.
- **Settings Widgets**: `mobile/lib/core/widgets/settings_widgets.dart` menyatukan elemen interaktif seperti Switch dan List Tiles untuk pengaturan aplikasi.

---

<!-- ## 🗄️ Database Schema

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   users     │     │   staff     │     │ categories  │
│─────────────│     │─────────────│     │─────────────│
│ id          │     │ id          │     │ id          │
│ sso_id      │     │ name        │     │ name        │
│ name        │     │ email       │     │ type        │
│ email       │     │ password    │     │ icon        │
│ phone       │     │ role        │     └─────────────┘
│ faculty     │     │ is_active   │
│ department  │     └──────┬──────┘
└──────┬──────┘            │
       │                   │
       │    ┌──────────────┴──────────────┐
       │    │           reports           │
       │    │─────────────────────────────│
       └────│ user_id, category_id        │
            │ title, description          │
            │ building, latitude, longitude│
            │ image_url, is_emergency     │
            │ status, assigned_to         │────┐
            │ handler_notes, handler_media_url│
            └──────────────────────────────────┘
                          │
                          ▼
                ┌─────────────────┐
                │  report_logs    │
                │─────────────────│
                │ report_id       │
                │ staff_id        │
                │ action          │
                │ notes           │
                └─────────────────┘
``` -->

### Status Lifecycle Laporan

Sistem membedakan alur verifikasi berdasarkan tingkat urgensi laporan (Darurat vs Non-Darurat). PENDING dalam Bahasa Indonesia diistilahkan sebagai **"Menunggu"** atau **"Menunggu Verifikasi"**.

#### 🟢 Alur Non-Darurat
Laporan melewati verifikasi wilayah oleh PJ Gedung sebelum diteruskan ke Supervisor.

```text
[Pelapor membuat laporan : PENDING]
              │
              ▼
[PJ Gedung Verifikasi : TERVERIFIKASI] ──► [Laporan tidak valid : TOLAK] ──► [ARSIP]
              │
              ▼
[Supervisor alokasi teknisi : DIPROSES]
              │
              ▼
[Teknisi Menerima & Menangani : PENANGANAN] ◄────────────────┐
              │                                              │
              ▼                                         (RECALLED)
[Teknisi Menyelesaikan : SELESAI] ───(Supervisor Re-Review)──┘
              │
              ▼
[Supervisor Approval : APPROVED] ──► [ARSIP]
```

#### 🔴 Alur Darurat
Laporan melewati tahap PJ Gedung dan langsung masuk ke antrean alokasi Supervisor (Fast-track).

```text
[Pelapor membuat laporan : PENDING]
              │
              ▼
[Supervisor alokasi teknisi : DIPROSES]
              │
              ▼
[Teknisi Menerima & Menangani : PENANGANAN] ◄────────────────┐
              │                                              │
              ▼                                         (RECALLED)
[Teknisi Menyelesaikan : SELESAI] ───(Supervisor Re-Review)──┘
              │
              ▼
[Supervisor Approval : APPROVED] ──► [ARSIP]
```

| Status | Deskripsi |
|--------|-----------|
| **PENDING** | Laporan baru masuk, menunggu verifikasi awal dari **PJ Gedung**. |
| **TERVERIFIKASI** | Sudah diverifikasi lokasi oleh PJ Gedung, menunggu alokasi teknisi oleh **Supervisor**. |
| **DIPROSES** | Teknisi sudah ditugaskan, menunggu konfirmasi teknisi untuk mulai bekerja. |
| **PENANGANAN** | Laporan sedang dalam proses pengerjaan oleh **Teknisi**. |
| **ON HOLD** | Pengerjaan ditunda sementara oleh teknisi (contoh: menunggu *sparepart*). |
| **SELESAI** | Teknisi selesai bekerja, menunggu persetujuan akhir dari **Supervisor**. |
| **APPROVED** | Supervisor menyetujui hasil, laporan dianggap selesai dan diarsipkan. |
| **RECALLED** | Supervisor menolak hasil pengerjaan, teknisi diminta menangani kembali. |
| **DITOLAK** | Laporan ditolak di tahap verifikasi (karena tidak valid atau duplikat). |
| **ARSIP** | Logika history untuk laporan yang sudah berada di state final (Approved/Ditolak). |

---

## 🚀 Setup & Instalasi

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.9.2)
- [Bun](https://bun.sh/) (latest)
- [PostgreSQL](https://www.postgresql.org/download/) (latest)

### 1. Clone Repository

```bash
git clone https://github.com/[username]/lapor-fsm.git
cd lapor-fsm
```

### 2. Backend Setup

```bash
# Masuk ke folder backend
cd backend

# Copy environment file
cp .env.example .env

# Edit .env dengan kredensial database Anda
# DATABASE_URL=postgres://postgres:postgres@localhost:5432/laporfsm
# JWT_SECRET=your-secret-key

# Install dependencies
bun install

# Jalankan database migration (jika diperlukan)
bun run drizzle-kit push

# Seed data awal (opsional)
bun run src/db/seed.ts

# Jalankan server development
bun run dev
```

Server akan berjalan di `http://localhost:3000`

### 3. Mobile Setup

```bash
# Masuk ke folder mobile
cd mobile

# Install Flutter dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### 4. Konfigurasi API Endpoint

Edit konfigurasi API di:
- `mobile/lib/core/services/` untuk mengubah base URL API

---

<!-- ## 📖 Dokumentasi API

### Base URL
```
http://localhost:3000
```

### Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| `GET` | `/` | Health check |
| **Auth** |||
| `POST` | `/auth/login` | Login untuk Pelapor (SSO) |
| `POST` | `/auth/staff/login` | Login untuk Staff |
| **Reports** |||
| `GET` | `/reports` | Daftar laporan |
| `POST` | `/reports` | Buat laporan baru |
| `GET` | `/reports/:id` | Detail laporan |
| `PATCH` | `/reports/:id/status` | Update status laporan |
| **Upload** |||
| `POST` | `/upload` | Upload file multimedia |

--- -->

## 📱 Fitur Per Role

### Pelapor (Reporter)
- ✅ Login dengan SSO Undip
- ✅ Home Page dengan Panic Button
- ✅ Form Laporan (Camera, GPS, Gedung)
- ✅ Public Feed dengan Filter
- ✅ Riwayat Laporan
- ✅ Detail Laporan dengan Timeline
- ✅ Halaman Profil
- ✅ Forgot Password

### Teknisi
- ✅ Dashboard Laporan Masuk
- ✅ Validasi & Penanganan Laporan
- ✅ Map View Lokasi Laporan
- ✅ Upload Bukti Penanganan
- ✅ Riwayat Penanganan
- ✅ Profil & Settings

### PJ Gedung
- ✅ Dashboard Statistik Gedung Terfokus
- ✅ Manajemen Laporan per Gedung
- ✅ Validasi Awal Laporan
- ✅ Halaman Bantuan & Pengaturan Terstandarisasi
- ✅ Profil PJ Gedung

### Supervisor
- ✅ Dashboard Overview
- ✅ Review Hasil Penanganan
- ✅ Recall Teknisi (Penanganan Ulang)
- ✅ Arsip Laporan
- ✅ Export PDF/Excel
- ✅ Monitoring Kinerja Teknisi

### Admin
- ✅ Dashboard Statistik
- ✅ Manajemen User (Pelapor)
- ✅ Manajemen Staff (Teknisi, Supervisor)
- ✅ Manajemen Kategori Laporan
- ✅ Verifikasi Pendaftaran Baru
- ✅ Notifikasi Sistem

---

## 🔐 Proses Registrasi

Aplikasi mendukung dua jalur registrasi:

| Kriteria | Email `@undip.ac.id` | Email Non-Undip |
|----------|---------------------|-----------------|
| **Syarat Identitas** | Tidak wajib upload KTP/KTM | Wajib upload foto kartu identitas |
| **Aktivasi Akun** | Otomatis setelah verifikasi email | Manual (persetujuan Admin) |
| **Status Awal** | Langsung aktif | Menunggu Verifikasi Admin |

---

## 👥 Tim Pengembang

Proyek ini dikembangkan sebagai bagian dari **PKL (Praktek Kerja Lapangan) di UP2TI** oleh:

| Nama | Pembagian Role |
|------|----------------|
| **Syafiq Abiyyu Taqi** | Teknisi, Supervisor |
| **Sulhan Fuadi** | Pelapor, Admin, PJ Gedung |

---

## 📁 Struktur Work Division

```
Mobile (Flutter)
├── Shared: lib/core (router, services), lib/features/auth, lib/features/notification
├── Syafiq: lib/features/teknisi, lib/features/supervisor
└── Sulhan: lib/features/pelapor, lib/features/admin, lib/features/pj_gedung

Backend (ElysiaJS)
├── Shared: src/db, src/controllers/auth.controller.ts, src/controllers/notification.controller.ts, src/controllers/upload.controller.ts
├── Syafiq: src/controllers/technician, src/controllers/supervisor
└── Sulhan: src/controllers/reporter, src/controllers/admin, src/controllers/staff (PJ Gedung)
```

<!-- --- -->
<!-- 
## 📋 Metodologi Pengembangan

- **Agile Development**: Untuk fleksibilitas pengembangan fitur
- **ICONIX Process**: Pendekatan berorientasi objek -->

<!-- ### Diagram yang Dikembangkan
- Use Case Diagram
- Robustness Diagram
- Sequence Diagram
- Class Diagram -->

<!-- ---

## 📄 License

*Lisensi akan ditentukan kemudian* -->

---

## 🔗 Links

- **Repository**: `https://github.com/laporfsm/lapor-fsm`
- **UP2TI FSM Undip**: Unit Pengelola dan Pelayanan Teknologi Informasi Fakultas Sains dan Matematika Universitas Diponegoro Semarang

---

<p align="center">
  <strong>Fakultas Sains dan Matematika</strong><br/>
  Universitas Diponegoro<br/>
  © 2026
</p>
