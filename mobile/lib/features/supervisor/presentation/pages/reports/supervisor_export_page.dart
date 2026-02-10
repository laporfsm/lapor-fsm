import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';
import 'package:mobile/core/widgets/custom_date_range_picker.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/supervisor/presentation/pages/dashboard/supervisor_shell_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Conditional import for platform-specific file handling
import 'package:mobile/core/utils/file_download_helper.dart'
    if (dart.library.html) 'package:mobile/core/utils/file_download_helper_web.dart';

class SupervisorExportPage extends StatefulWidget {
  const SupervisorExportPage({super.key});

  @override
  State<SupervisorExportPage> createState() => _SupervisorExportPageState();
}

class _SupervisorExportPageState extends State<SupervisorExportPage> {
  // Format Selection
  String _selectedFormat = 'csv'; // csv, pdf, excel

  // Date Filter State
  String? _selectedPeriod; // 'today', 'week', 'month', 'year'
  DateTimeRange? _selectedDateRange;

  // Advanced Filters
  final Set<ReportStatus> _selectedStatuses = {};
  String? _selectedCategory;
  String? _selectedLocation;

  // Data
  List<String> _categories = [];
  List<String> _locations = [];
  List<Map<String, dynamic>> _previewData = [];
  bool _isLoadingPreview = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Default to 'This Month' for convenience
    _selectedPeriod = 'month';
    _applyPeriodPreset('month'); // Sets _selectedDateRange

    try {
      final cats = await reportService.getCategories();
      final builds = await reportService.getLocations();

      if (mounted) {
        setState(() {
          _categories = cats.map((e) => e['name'] as String).toList();
          _locations = builds.map((e) => e['name'] as String).toList();
        });
        _fetchPreview();
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  void _applyPeriodPreset(String period) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (period) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        // Indo starts Monday? Using standard ISO logic usually
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      default:
        return;
    }

    setState(() {
      _selectedPeriod = period;
      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
    _fetchPreview();
  }

  Future<void> _showCustomDateRangePicker() async {
    final newDateRange = await CustomDateRangePickerDialog.show(
      context: context,
      initialRange: _selectedDateRange,
      themeColor: supervisorColor,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
        _selectedPeriod = null; // Clear preset
      });
      _fetchPreview();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  const Gap(16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedStatuses.clear();
                              _selectedCategory = null;
                              _selectedLocation = null;
                            });
                            setState(
                              () {},
                            ); // Updates parent if needed (but we wait for Terapkan)
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Text(
                          'Filter Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchPreview();
                          },
                          child: const Text(
                            'Terapkan',
                            style: TextStyle(
                              color: supervisorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Status
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ReportStatus.values
                              .where(
                                (s) =>
                                    s.name != 'verifikasi' &&
                                    s.name != 'archived',
                              )
                              .map<Widget>((status) {
                                final isSelected = _selectedStatuses.contains(
                                  status,
                                );
                                return FilterChip(
                                  label: Text(status.label),
                                  selected: isSelected,
                                  selectedColor: status.color.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: status.color,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? status.color
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedStatuses.add(status);
                                      } else {
                                        _selectedStatuses.remove(status);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              })
                              .toList(),
                        ),
                        const Gap(20),

                        // Kategori
                        const Text(
                          'Kategori',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: supervisorColor.withValues(
                                alpha: 0.2,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? supervisorColor
                                    : Colors.black87,
                              ),
                              onSelected: (selected) {
                                setModalState(
                                  () =>
                                      _selectedCategory = selected ? cat : null,
                                );
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(20),

                        // Lokasi (Lokasi)
                        const Text(
                          'Lokasi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _locations.map((location) {
                            final isSelected = _selectedLocation == location;
                            return ChoiceChip(
                              label: Text(location),
                              selected: isSelected,
                              selectedColor: Colors.teal.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.teal
                                    : Colors.black87,
                              ),
                              onSelected: (selected) {
                                setModalState(
                                  () => _selectedLocation = selected
                                      ? location
                                      : null,
                                );
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const Gap(40),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _fetchPreview() async {
    setState(() => _isLoadingPreview = true);

    // Mock Delay
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final response = await reportService.getPublicReports(
        status: _selectedStatuses.isNotEmpty
            ? _selectedStatuses.map((s) => s.name).join(',')
            : null,
        category: _selectedCategory,
        location: _selectedLocation,
        limit: 5,
        startDate: _selectedDateRange?.start.toIso8601String(),
        endDate: _selectedDateRange?.end.toIso8601String(),
      );

      final List<Map<String, dynamic>> reports =
          List<Map<String, dynamic>>.from(response['data'] ?? []);

      if (mounted) {
        setState(() {
          // Safe mapping to prevent null crashes
          _previewData = reports.map((r) {
            final dateStr = r['createdAt'] ?? '';
            DateTime? date;
            if (dateStr.isNotEmpty) {
              date = DateTime.tryParse(dateStr);
            }

            final handledByList = r['handledBy'];
            String technician = '-';
            if (handledByList is List && handledByList.isNotEmpty) {
              technician = handledByList.first.toString();
              if (handledByList.length > 1) {
                technician += ' +${handledByList.length - 1}';
              }
            } else if (r['technician'] != null) {
              technician = r['technician']['name'] ?? '-';
            }

            // Prioritas
            final isEmergency = r['isEmergency'] == true;

            // Lokasi lengkap
            final location = r['location'] ?? '-';
            final locationDetail = r['locationDetail'];
            final fullLocation =
                locationDetail != null && locationDetail.toString().isNotEmpty
                ? '$location - $locationDetail'
                : location.toString();

            return {
              'date': date != null
                  ? DateFormat('yyyy-MM-dd').format(date)
                  : '-',
              'title': (r['title'] ?? 'Tanpa Judul').toString(),
              'category': (r['category'] ?? '-').toString(),
              'status': (r['status'] ?? 'pending').toString(),
              'technician': technician,
              'isEmergency': isEmergency,
              'reporterName': (r['reporterName'] ?? '-').toString(),
              'location': fullLocation,
            };
          }).toList();
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _handleExport() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Menyiapkan file export...')));

    try {
      // Fetch full logic without limit
      final response = await reportService.getPublicReports(
        status: _selectedStatuses.isNotEmpty
            ? _selectedStatuses.map((s) => s.name).join(',')
            : null,
        category: _selectedCategory,
        location: _selectedLocation,
        limit: 2000,
        startDate: _selectedDateRange?.start.toIso8601String(),
        endDate: _selectedDateRange?.end.toIso8601String(),
      );

      final List<Map<String, dynamic>> reports =
          List<Map<String, dynamic>>.from(response['data'] ?? []);

      if (reports.isEmpty) {
        throw Exception('Tidak ada data yang sesuai filter');
      }

      List<int>? fileBytes;
      String extension = _selectedFormat;
      String mimeType = 'text/csv';

      if (_selectedFormat == 'excel') {
        fileBytes = await _generateExcel(reports);
        extension = 'xlsx';
        mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (_selectedFormat == 'pdf') {
        fileBytes = await _generatePdf(reports);
        extension = 'pdf';
        mimeType = 'application/pdf';
      } else {
        fileBytes = _generateCsv(reports);
        extension = 'csv';
        mimeType = 'text/csv';
      }

      final fileName =
          'lapor_fsm_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$extension';

      // Check if running on web platform
      if (kIsWeb) {
        // For web: use browser download API via helper
        await downloadFileWeb(
          Uint8List.fromList(fileBytes),
          fileName,
          mimeType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File $fileName berhasil didownload!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // For native platforms (Android/iOS): use helper function
        await saveAndShareFileNative(
          Uint8List.fromList(fileBytes),
          fileName,
          mimeType,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<int> _generateCsv(List<Map<String, dynamic>> data) {
    String csv =
        'ID,Tanggal Dibuat,Prioritas,Judul,Deskripsi,Kategori,Status,Lokasi,Detail Lokasi,Pelapor,Email Pelapor,Teknisi,Tanggal Selesai,Durasi (jam)\n';
    for (var r in data) {
      final createdAt = r['createdAt'] != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(DateTime.parse(r['createdAt']))
          : '-';

      final completedAt = r['completedAt'] != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(DateTime.parse(r['completedAt']))
          : '-';

      // Calculate duration if both dates exist
      String duration = '-';
      if (r['createdAt'] != null && r['completedAt'] != null) {
        final start = DateTime.parse(r['createdAt']);
        final end = DateTime.parse(r['completedAt']);
        final diff = end.difference(start);
        duration = (diff.inMinutes / 60).toStringAsFixed(1);
      }

      String technician = '-';
      if (r['handledBy'] is List && (r['handledBy'] as List).isNotEmpty) {
        technician = (r['handledBy'] as List)
            .map((t) => t.toString())
            .join('; ');
      } else if (r['technician'] != null) {
        technician = r['technician']['name'] ?? '-';
      }

      final isEmergency = r['isEmergency'] == true ? 'Darurat' : 'Normal';

      // Escape quotes in string fields
      String escapeField(dynamic value) {
        final str = (value ?? '-').toString().replaceAll('"', '""');
        return '"$str"';
      }

      csv +=
          '${r['id']},'
          '${escapeField(createdAt)},'
          '${escapeField(isEmergency)},'
          '${escapeField(r['title'])},'
          '${escapeField(r['description'])},'
          '${escapeField(r['category'])},'
          '${escapeField(r['status'])},'
          '${escapeField(r['location'])},'
          '${escapeField(r['locationDetail'])},'
          '${escapeField(r['reporterName'])},'
          '${escapeField(r['reporterEmail'])},'
          '${escapeField(technician)},'
          '${escapeField(completedAt)},'
          '${escapeField(duration)}\n';
    }
    return csv.codeUnits;
  }

  Future<List<int>> _generateExcel(List<Map<String, dynamic>> data) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Laporan'];

    // Delete default Sheet1 so Laporan becomes the first sheet
    excel.delete('Sheet1');

    // Header row with styling
    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Tanggal Dibuat'),
      TextCellValue('Prioritas'),
      TextCellValue('Judul'),
      TextCellValue('Deskripsi'),
      TextCellValue('Kategori'),
      TextCellValue('Status'),
      TextCellValue('Lokasi'),
      TextCellValue('Detail Lokasi'),
      TextCellValue('Pelapor'),
      TextCellValue('Email Pelapor'),
      TextCellValue('Teknisi'),
      TextCellValue('Tanggal Selesai'),
      TextCellValue('Durasi (jam)'),
    ]);

    for (var r in data) {
      final createdAt = r['createdAt'] != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(DateTime.parse(r['createdAt']))
          : '-';

      final completedAt = r['completedAt'] != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(DateTime.parse(r['completedAt']))
          : '-';

      // Calculate duration if both dates exist
      String duration = '-';
      if (r['createdAt'] != null && r['completedAt'] != null) {
        final start = DateTime.parse(r['createdAt']);
        final end = DateTime.parse(r['completedAt']);
        final diff = end.difference(start);
        duration = (diff.inMinutes / 60).toStringAsFixed(1);
      }

      String technician = '-';
      if (r['handledBy'] is List && (r['handledBy'] as List).isNotEmpty) {
        technician = (r['handledBy'] as List).join(', ');
      } else if (r['technician'] != null) {
        technician = r['technician']['name'] ?? '-';
      }

      final isEmergency = r['isEmergency'] == true ? 'Darurat' : 'Normal';

      sheetObject.appendRow([
        IntCellValue(
          r['id'] is int ? r['id'] : int.tryParse(r['id'].toString()) ?? 0,
        ),
        TextCellValue(createdAt),
        TextCellValue(isEmergency),
        TextCellValue(r['title'] ?? '-'),
        TextCellValue(r['description'] ?? '-'),
        TextCellValue(r['category'] ?? '-'),
        TextCellValue(r['status'] ?? '-'),
        TextCellValue(r['location'] ?? '-'),
        TextCellValue(r['locationDetail'] ?? '-'),
        TextCellValue(r['reporterName'] ?? '-'),
        TextCellValue(r['reporterEmail'] ?? '-'),
        TextCellValue(technician),
        TextCellValue(completedAt),
        TextCellValue(duration),
      ]);
    }

    return excel.encode() ?? [];
  }

  Future<List<int>> _generatePdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Laporan FSM Export')),
          pw.Paragraph(
            text:
                'Tanggal Export: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: [
              'ID',
              'Tanggal',
              'Prioritas',
              'Judul',
              'Kategori',
              'Status',
              'Lokasi',
              'Pelapor',
              'Teknisi',
              'Durasi',
            ],
            data: data.map((r) {
              final createdAt = r['createdAt'] != null
                  ? DateFormat(
                      'dd/MM/yy',
                    ).format(DateTime.parse(r['createdAt']))
                  : '-';

              // Calculate duration if both dates exist
              String duration = '-';
              if (r['createdAt'] != null && r['completedAt'] != null) {
                final start = DateTime.parse(r['createdAt']);
                final end = DateTime.parse(r['completedAt']);
                final diff = end.difference(start);
                duration = '${(diff.inMinutes / 60).toStringAsFixed(1)}h';
              }

              String technician = '-';
              if (r['handledBy'] is List &&
                  (r['handledBy'] as List).isNotEmpty) {
                technician = (r['handledBy'] as List).first.toString();
              } else if (r['technician'] != null) {
                technician = r['technician']['name'] ?? '-';
              }

              final isEmergency = r['isEmergency'] == true
                  ? 'Darurat'
                  : 'Normal';

              // Truncate long text for PDF
              String truncate(String? text, int maxLen) {
                if (text == null) return '-';
                return text.length > maxLen
                    ? '${text.substring(0, maxLen)}...'
                    : text;
              }

              return [
                r['id'].toString(),
                createdAt,
                isEmergency,
                truncate(r['title'], 25),
                r['category'] ?? '-',
                r['status'] ?? '-',
                truncate(r['location'], 15),
                truncate(r['reporterName'], 12),
                truncate(technician, 12),
                duration,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              5: pw.Alignment.center,
              9: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Export Laporan'),
        backgroundColor: supervisorColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Format File Section
                const Text(
                  'Format File',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFormat,
                      isExpanded: true,
                      icon: const Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: Colors.grey,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'csv',
                          child: Text('CSV - Data Mentah'),
                        ),
                        DropdownMenuItem(
                          value: 'pdf',
                          child: Text('PDF - Dokumen Siap Cetak'),
                        ),
                        DropdownMenuItem(
                          value: 'excel',
                          child: Text('Excel (.xlsx) - Data Olahan'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFormat = v);
                      },
                    ),
                  ),
                ),
                const Gap(16),

                // Filters
                const Text(
                  'Filter',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Gap(8),
                // Period Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip('Hari Ini', 'today'),
                      const Gap(8),
                      _buildPeriodChip('Minggu Ini', 'week'),
                      const Gap(8),
                      _buildPeriodChip('Bulan Ini', 'month'),
                      const Gap(8),
                      _buildPeriodChip('Tahun Ini', 'year'),
                    ],
                  ),
                ),
                const Gap(12),

                // Buttons: Calendar & Filter
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _showCustomDateRangePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 20,
                                color:
                                    _selectedPeriod == null &&
                                        _selectedDateRange != null
                                    ? supervisorColor
                                    : Colors.grey,
                              ),
                              const Gap(12),
                              Expanded(
                                child: Text(
                                  _selectedPeriod == null &&
                                          _selectedDateRange != null
                                      ? '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
                                      : 'Pilih Tanggal Manual',
                                  style: TextStyle(
                                    color:
                                        _selectedPeriod == null &&
                                            _selectedDateRange != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    BouncingButton(
                      onTap: _showFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (_selectedStatuses.isNotEmpty ||
                                  _selectedCategory != null ||
                                  _selectedLocation != null)
                              ? supervisorColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          LucideIcons.slidersHorizontal,
                          color:
                              (_selectedStatuses.isNotEmpty ||
                                  _selectedCategory != null ||
                                  _selectedLocation != null)
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildPreviewTable(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoadingPreview ? null : _handleExport,
          icon: const Icon(LucideIcons.download),
          label: Text('Download $_selectedFormat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: supervisorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _applyPeriodPreset(value);
      },
      selectedColor: supervisorColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? supervisorColor : Colors.grey.shade300,
        ),
      ),
      checkmarkColor: isSelected ? Colors.white : null,
    );
  }

  Widget _buildPreviewTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Preview Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: ${_previewData.length} (Max 5 Preview)',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _isLoadingPreview
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _previewData.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('Tidak ada data yang sesuai filter'),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 40,
                    dataRowMinHeight: 40,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Tanggal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Prioritas',
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
                          'Lokasi',
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
                          'Pelapor',
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
                      Color statusColor = Colors.grey;
                      String statusLower = data['status']
                          .toString()
                          .toLowerCase();
                      if (statusLower == 'selesai' ||
                          statusLower == 'approved') {
                        statusColor = Colors.green;
                      } else if (statusLower == 'terverifikasi' ||
                          statusLower == 'verifikasi') {
                        statusColor = Colors.blue;
                      } else if (statusLower == 'diproses') {
                        statusColor = Colors.orange;
                      } else if (statusLower == 'onhold') {
                        statusColor = Colors.amber;
                      } else if (statusLower == 'ditolak') {
                        statusColor = Colors.red;
                      }

                      final isEmergency = data['isEmergency'] == true;

                      return DataRow(
                        cells: [
                          DataCell(Text(data['date'].toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isEmergency
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isEmergency ? 'Darurat' : 'Normal',
                                style: TextStyle(
                                  color: isEmergency
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                data['title'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text(
                                data['location'].toString(),
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
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data['status'].toString(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 80,
                              child: Text(
                                data['reporterName'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(data['technician'].toString())),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        const Gap(8),
        Text(
          '* Preview hanya menampilkan 5 data terbaru sesuai filter',
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
