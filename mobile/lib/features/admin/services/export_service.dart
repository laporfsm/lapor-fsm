import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:excel/excel.dart';
import 'package:mobile/core/utils/save_file.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  static Future<void> exportData(
    BuildContext context,
    String title,
    String dataType, {
    List<dynamic>? data,
  }) async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text('Menyiapkan file Excel $dataType...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (data == null || data.isEmpty) {
        throw Exception('Tidak ada data untuk diekspor');
      }

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Header Style
      final CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(
          '#059669',
        ), // Emerald Green
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // Define Columns
      final List<String> headers = [
        'No',
        'Tanggal',
        'Judul Laporan',
        'Kategori',
        'Gedung',
        'Detail Lokasi',
        'Pelapor',
        'Status',
        'Darurat',
      ];

      // Add Headers
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add Data
      for (var i = 0; i < data.length; i++) {
        final rowData = data[i];
        final rowIndex = i + 1;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = IntCellValue(
          rowIndex,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['createdAt']?.toString().split('T').first ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['title'] ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['category'] ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['building'] ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['locationDetail'] ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['reporterName'] ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['status'] ?? '-',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          rowData['isEmergency'] == true ? 'YA' : 'TIDAK',
        );
      }

      // Finalize file
      // Use encode() instead of save() to get bytes without triggering library's auto-download
      final fileBytes = excel.encode();

      if (fileBytes != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = "${title.replaceAll(' ', '_')}_$timestamp.xlsx";
        await saveFile(
          fileBytes,
          fileName,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengekspor $title ke Excel (.xlsx)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> exportLogsExcel(
    BuildContext context,
    List<Map<String, dynamic>> logs,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan file Excel Log Sistem...'),
        duration: Duration(seconds: 1),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (logs.isEmpty) {
        throw Exception('Tidak ada log untuk diekspor');
      }

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      final CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#059669'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final List<String> headers = ['No', 'Waktu', 'User', 'Aksi', 'Detail'];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < logs.length; i++) {
        final log = logs[i];
        final rowIndex = i + 1;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(rowIndex);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(log['time']),
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(log['user'] ?? '-');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(log['action'] ?? '-');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(log['details'] ?? '-');
      }

      final fileBytes = excel.encode();

      if (fileBytes != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = "Log_Sistem_User_$timestamp.xlsx";
        await saveFile(
          fileBytes,
          fileName,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengekspor Log ke Excel'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> exportPdf({
    required BuildContext context,
    required String title,
    String? status,
    String? building,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menghubungi server untuk pembuatan PDF...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final queryParams = {
        if (status != null) 'status': status,
        if (building != null) 'building': building,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (search != null) 'search': search,
      };

      final response = await apiService.dio.get(
        '/pj-gedung/reports/export/pdf',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = "${title.replaceAll(' ', '_')}_$timestamp.pdf";
      await saveFile(response.data, fileName, 'application/pdf');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengunduh $title (.pdf)'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> generateAdminLogsPdf({
    required BuildContext context,
    required List<Map<String, dynamic>> logs,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan file PDF Log Sistem...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.interRegular();
      final fontBold = await PdfGoogleFonts.interBold();

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Log Aktivitas Sistem - User',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'No',
                'Waktu',
                'User',
                'Aksi',
                'Detail',
              ],
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FixedColumnWidth(60),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FlexColumnWidth(),
              },
              data: List.generate(logs.length, (index) {
                final log = logs[index];
                return [
                  (index + 1).toString(),
                  DateFormat('dd/MM HH:mm').format(log['time']),
                  log['user'] ?? '-',
                  log['action'] ?? '-',
                  log['details'] ?? '-',
                ];
              }),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellStyle: const pw.TextStyle(fontSize: 9),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = "Log_Sistem_User_$timestamp.pdf";
      
      await saveFile(bytes, fileName, 'application/pdf');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengunduh $fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF Log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
