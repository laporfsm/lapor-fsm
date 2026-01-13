# Lapor FSM!

Sistem Pelaporan Insiden & Fasilitas untuk civitas akademika FSM Undip (Mahasiswa & Dosen).

## Struktur Proyek

Repositori ini adalah Monorepo yang berisi kode untuk Mobile Apps dan Backend API.

```text
/
├── mobile/   # Aplikasi Flutter (Android/iOS)
└── backend/  # Server ElysiaJS + Bun (API)
```

## Setup & Instalasi

### 1. Backend (ElysiaJS)
Masuk ke folder backend dan install dependencies:

```bash
cd backend
bun install
bun run src/index.ts
```

### 2. Mobile (Flutter)
Masuk ke folder mobile dan jalankan aplikasi:

```bash
cd mobile
flutter pub get
flutter run
```

## Pembagian Peran

Proyek ini dikerjakan oleh tim 2 orang:
- **Taki**: Teknisi, Supervisor, Admin.
- **Fuad**: Pelapor.

## Fitur Utama

- **Pelaporan Insiden**: Medis, Keamanan, Infrastruktur, K3 Lab.
- **Real-time Tracking**: Lokasi pelapor darurat (Live Tracking).
- **Manajemen Laporan**: Validasi, Penanganan, Timer Durasi.
- **Monitoring**: Dashboard Supervisor & Admin.

## Teknologi
- **Frontend**: Flutter
- **Backend**: ElysiaJS + Bun, WebSockets
- **Database**: PostgreSQL
