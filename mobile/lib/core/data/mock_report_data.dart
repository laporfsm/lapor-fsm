import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/entities/report_log.dart';

/// Centralized mock report data - shared across all detail pages
/// This ensures consistency between cards and detail pages
///
/// Usage:
/// ```dart
/// final report = MockReportData.getReport('1');
/// ```
class MockReportData {
  /// Get a mock report by ID
  static Report? getReport(String id) => _reports[id];

  /// Get all reports as a list
  static List<Report> get allReports => _reports.values.toList();

  /// Get a report with fallback for unknown IDs
  static Report getReportOrDefault(String id) {
    return _reports[id] ??
        Report(
          id: id,
          title: 'Laporan #$id',
          description: 'Detail laporan tidak ditemukan',
          category: 'Lainnya',
          building: 'Gedung A',
          status: ReportStatus.pending,
          isEmergency: false,
          createdAt: DateTime.now(),
          reporterId: 'unknown',
          reporterName: 'Unknown',
          logs: [],
        );
  }

  static final Map<String, Report> _reports = {
    // ===== Feed Page Reports (ID 1-4) =====
    '1': Report(
      id: '1',
      title: 'AC Mati di Ruang E102',
      description:
          'AC di ruang E102 tidak menyala sejak pagi. Ruangan menjadi sangat panas dan tidak kondusif.',
      category: 'Maintenance',
      building: 'Gedung E',
      latitude: -6.998576,
      longitude: 110.423188,
      status: ReportStatus.diproses,
      isEmergency: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      reporterId: 'user1',
      reporterName: 'Ahmad Fauzi',
      reporterEmail: 'ahmad@student.undip.ac.id',
      reporterPhone: '081234567890',
      handledBy: ['Budi Santoso'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1631545806609-35d4d48b1d10?w=400',
        'https://images.unsplash.com/photo-1585128792020-803d29415281?w=400',
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      ],
      logs: [
        ReportLog(
          id: '2',
          fromStatus: ReportStatus.verifikasi,
          toStatus: ReportStatus.penanganan,
          action: ReportAction.handling,
          actorId: 'tech1',
          actorName: 'Budi Santoso',
          actorRole: 'Teknisi',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ReportLog(
          id: '1',
          fromStatus: ReportStatus.pending,
          toStatus: ReportStatus.pending,
          action: ReportAction.created,
          actorId: 'user1',
          actorName: 'Ahmad Fauzi',
          actorRole: 'Pelapor',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    ),
    '2': Report(
      id: '2',
      title: 'Kebocoran Pipa Toilet',
      description:
          'Pipa di toilet lantai 1 bocor menyebabkan genangan air. Perlu penanganan segera.',
      category: 'Maintenance',
      building: 'Gedung C',
      latitude: -6.997200,
      longitude: 110.420500,
      status: ReportStatus.diproses,
      isEmergency: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      reporterId: 'user2',
      reporterName: 'Siti Aminah',
      reporterEmail: 'siti@student.undip.ac.id',
      reporterPhone: '081234567891',
      handledBy: ['Budi Santoso'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
        'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=400',
      ],
      logs: [
        ReportLog(
          id: '2',
          fromStatus: ReportStatus.pending,
          toStatus: ReportStatus.verifikasi,
          action: ReportAction.verified,
          actorId: 'tech1',
          actorName: 'Budi Santoso',
          actorRole: 'Teknisi',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        ReportLog(
          id: '1',
          fromStatus: ReportStatus.pending,
          toStatus: ReportStatus.pending,
          action: ReportAction.created,
          actorId: 'user2',
          actorName: 'Siti Aminah',
          actorRole: 'Pelapor',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
    ),
    '3': Report(
      id: '3',
      title: 'Kebakaran di Lab Kimia',
      description:
          'Terjadi kebakaran kecil di lab kimia. Api sudah dipadamkan tetapi perlu inspeksi lanjutan.',
      category: 'Emergency',
      building: 'Gedung D',
      latitude: -6.996000,
      longitude: 110.419000,
      status: ReportStatus.diproses,
      isEmergency: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      reporterId: 'user3',
      reporterName: 'Rudi Hartono',
      reporterEmail: 'rudi@student.undip.ac.id',
      reporterPhone: '081234567892',
      handledBy: ['Budi Santoso', 'Joko Susilo'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1582560469781-1bf764d87fa2?w=400',
        'https://images.unsplash.com/photo-1573166953836-06864dc70a21?w=400',
      ],
      logs: [
        ReportLog(
          id: '2',
          fromStatus: ReportStatus.pending,
          toStatus: ReportStatus.penanganan,
          action: ReportAction.handling,
          actorId: 'tech1',
          actorName: 'Budi Santoso',
          actorRole: 'Teknisi',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          reason: 'Laporan darurat - langsung ditangani',
        ),
        ReportLog(
          id: '1',
          fromStatus: ReportStatus.pending,
          toStatus: ReportStatus.pending,
          action: ReportAction.created,
          actorId: 'user3',
          actorName: 'Rudi Hartono',
          actorRole: 'Pelapor',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    ),
    '4': Report(
      id: '4',
      title: 'Sampah Menumpuk Area Parkir',
      description:
          'Sampah di area parkir sudah menumpuk dan tidak diangkut sejak kemarin. Menimbulkan bau tidak sedap.',
      category: 'Kebersihan',
      building: 'Gedung A',
      latitude: -6.999000,
      longitude: 110.422000,
      status: ReportStatus.penanganan,
      isEmergency: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      reporterId: 'user4',
      reporterName: 'Dewi Lestari',
      reporterEmail: 'dewi@student.undip.ac.id',
      reporterPhone: '081234567893',
      mediaUrls: [
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
        'https://images.unsplash.com/photo-1605600659908-0ef719419d41?w=400',
      ],
      logs: [
        ReportLog(
          id: '1',
          fromStatus: ReportStatus.pending,
          toStatus: ReportStatus.pending,
          action: ReportAction.created,
          actorId: 'user4',
          actorName: 'Dewi Lestari',
          actorRole: 'Pelapor',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),

    // ===== DATA BARU YANG LEBIH LENGKAP =====
    '5': Report(
      id: '5',
      title: 'Lampu PJU Padam',
      description: 'Lampu penerangan jalan umum di depan Gedung H mati total.',
      category: 'Kelistrikan',
      building: 'Gedung H',
      locationDetail: 'Depan pintu masuk utama',
      latitude: -6.998200,
      longitude: 110.424500,
      status: ReportStatus.pending,
      isEmergency: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      reporterId: 'user5',
      reporterName: 'Bambang Pamungkas',
      reporterEmail: 'bambang@student.undip.ac.id',
      mediaUrls: [
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      ],
      logs: [],
    ),
    '6': Report(
      id: '6',
      title: 'Pintu Kaca Pecah',
      description: 'Pintu kaca lobi pecah akibat tersenggol troli barang.',
      category: 'Sipil & Bangunan',
      building: 'Gedung Rektorat',
      locationDetail: 'Lobi Utama',
      latitude: -6.997000,
      longitude: 110.421000,
      status: ReportStatus.diproses,
      isEmergency: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      reporterId: 'user_satpam',
      reporterName: 'Pak Slamet (Satpam)',
      handledBy: ['Tim Sipil A'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1600607686527-6fb886090705?w=400',
      ],
    ),
    '7': Report(
      id: '7',
      title: 'Wastafel Mampet',
      description: 'Air di wastafel toilet wanita tidak mengalir lancar.',
      category: 'Sanitasi',
      building: 'Gedung B',
      locationDetail: 'Lt 3, Toilet Wanita',
      latitude: -6.996500,
      longitude: 110.419200,
      status: ReportStatus.selesai,
      isEmergency: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      reporterId: 'user_cl',
      reporterName: 'Ibu Murni (Cleaning)',
      handledBy: ['Budi Santoso'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400',
      ],
    ),
    // ... bisa ditambahkan lebih banyak lagi sesuai kebutuhan ...
  };
}
