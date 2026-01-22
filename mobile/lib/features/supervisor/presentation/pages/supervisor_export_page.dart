import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:intl/intl.dart';

class SupervisorExportPage extends StatefulWidget {
  const SupervisorExportPage({super.key});

  @override
  State<SupervisorExportPage> createState() => _SupervisorExportPageState();
}

class _SupervisorExportPageState extends State<SupervisorExportPage> {
  DateTimeRange? _selectedDateRange;
  String _selectedCategory = 'Semua Kategori';
  String _selectedStatus = 'Semua Status';
  String _selectedFormat = 'PDF (Laporan Resmi)';

  final List<String> _categories = [
    'Semua Kategori',
    'Kerusakan Hardware',
    'Software / OS',
    'Jaringan / Internet',
    'Fasilitas Umum',
    'Kelistrikan',
  ];

  final List<String> _statuses = [
    'Semua Status',
    'Selesai',
    'Pending',
    'Verifikasi',
    'Penanganan',
  ];

  final List<String> _formats = [
    'PDF (Laporan Resmi)',
    'Excel (.xlsx) - Data Olahan',
    'CSV - Data Mentah',
  ];

  // Mock Data for Preview
  final List<Map<String, dynamic>> _previewData = [
    {
      'date': '2024-01-16',
      'title': 'AC Mati di Lab Komputer',
      'category': 'Fasilitas Umum',
      'status': 'Selesai',
      'technician': 'Budi Teknisi',
    },
    {
      'date': '2024-01-16',
      'title': 'Kebocoran Pipa Toilet',
      'category': 'Fasilitas Umum',
      'status': 'Verifikasi',
      'technician': 'Andi Teknisi',
    },
    {
      'date': '2024-01-15',
      'title': 'PC No. 5 Blue Screen',
      'category': 'Hardware',
      'status': 'Selesai',
      'technician': 'Citra Teknisi',
    },
    {
      'date': '2024-01-15',
      'title': 'Wifi Lantai 2 Lemot',
      'category': 'Jaringan',
      'status': 'Pending',
      'technician': '-',
    },
    {
      'date': '2024-01-14',
      'title': 'Proyektor Ruang Rapat',
      'category': 'Hardware',
      'status': 'Selesai',
      'technician': 'Budi Teknisi',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Export Laporan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsSection(),
            const Gap(24),
            _buildPreviewSection(),
            const Gap(80), // Space for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mengunduh $_selectedFormat...'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // TODO: [BACKEND] Implement actual file generation and download
            },
            icon: const Icon(LucideIcons.download),
            label: Text('Download $_selectedFormat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan Export',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(20),

          // Date Range Picker
          const Text(
            'Rentang Tanggal',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Gap(8),
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                initialDateRange:
                    _selectedDateRange ??
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    ),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: AppTheme.primaryColor,
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
                          : 'Pilih Rentang Tanggal',
                      style: TextStyle(
                        color: _selectedDateRange != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          const Gap(16),

          // Kategori & Status Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Gap(8),
                    _buildDropdown(_categories, _selectedCategory, (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    }),
                  ],
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Gap(8),
                    _buildDropdown(_statuses, _selectedStatus, (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    }),
                  ],
                ),
              ),
            ],
          ),

          const Gap(16),

          // Format File
          const Text(
            'Format File',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Gap(8),
          _buildDropdown(_formats, _selectedFormat, (val) {
            if (val != null) setState(() => _selectedFormat = val);
          }),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: Colors.grey,
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Preview Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: ${_previewData.length} Laporan',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(
                  label: Text(
                    'Tanggal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Judul Laporan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Teknisi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _previewData.map((data) {
                Color statusColor;
                switch (data['status']) {
                  case 'Selesai':
                    statusColor = Colors.green;
                    break;
                  case 'Pending':
                    statusColor = Colors.grey;
                    break;
                  case 'Verifikasi':
                    statusColor = Colors.blue;
                    break;
                  default:
                    statusColor = Colors.black;
                }

                return DataRow(
                  cells: [
                    DataCell(Text(data['date'])),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          data['title'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data['status'],
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(data['technician'])),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const Gap(8),
        Text(
          '* Preview hanya menampilkan 5 data awal',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
