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
    Color? primaryColor,
  }) async {
    final themeColor = primaryColor ?? const Color(0xFF059669); // Default to Emerald
    
    // Check if this is an Admin type that should be exported from server
    if (['user', 'verification_history', 'staff', 'laporan'].contains(dataType)) {
      _showExportOptions(context, title, dataType, themeColor);
      return;
    }

    // Existing local Excel export logic (for other types if any)
    _showLocalExcelExport(context, title, dataType, data, themeColor);
  }

  static void _showExportOptions(
    BuildContext context,
    String title,
    String dataType,
    Color themeColor,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Pilih Format Export - $title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Export ke Excel (.xlsx)'),
            onTap: () {
              Navigator.pop(context);
              _exportFromServer(context, title, dataType, 'excel', themeColor);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export ke PDF (.pdf)'),
            onTap: () {
              Navigator.pop(context);
              _exportFromServer(context, title, dataType, 'pdf', themeColor);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Future<void> _exportFromServer(
    BuildContext context,
    String title,
    String dataType,
    String format,
    Color themeColor,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mengunduh file $format...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      String endpoint = '';
      String contentType = '';

      if (dataType == 'laporan') {
        endpoint = '/admin/reports/export/$format';
      } else {
        endpoint = '/admin/users/export/$format';
      }

      contentType = format == 'excel'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'application/pdf';

      final response = await apiService.dio.get(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final finalFileName = "${title.replaceAll(' ', '_')}_$timestamp.${format == 'excel' ? 'xlsx' : 'pdf'}";

      await saveFile(response.data, finalFileName, contentType);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengunduh $title'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _showLocalExcelExport(
    BuildContext context,
    String title,
    String dataType,
    List<dynamic>? data,
    Color themeColor,
  ) async {
    final hexColor = '#${themeColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    
    if (data == null || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor'), backgroundColor: Colors.red),
        );
        return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      final CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(hexColor),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final List<String> headers = [
        'No', 'Tanggal', 'Judul Laporan', 'Kategori', 'Gedung', 'Detail Lokasi', 'Pelapor', 'Status', 'Darurat',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < data.length; i++) {
        final rowData = data[i];
        final rowIndex = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(rowIndex);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(rowData['createdAt']?.toString().split('T').first ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(rowData['title'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(rowData['category'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(rowData['building'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(rowData['locationDetail'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(rowData['reporterName'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(rowData['status'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = TextCellValue(rowData['isEmergency'] == true ? 'YA' : 'TIDAK');
      }

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = "${title.replaceAll(' ', '_')}_$timestamp.xlsx";
        await saveFile(fileBytes, fileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mengekspor $title ke Excel'), backgroundColor: themeColor),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static Future<void> exportLogsExcel(
    BuildContext context,
    List<Map<String, dynamic>> logs, {
    String title = 'Log Sistem',
    Color primaryColor = const Color(0xFF9333EA),
  }) async {
    final hexColor = '#${primaryColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menyiapkan file Excel $title...'),
        duration: const Duration(seconds: 1),
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
        backgroundColorHex: ExcelColor.fromHexString(hexColor),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final List<String> headers = ['No', 'Waktu', 'User', 'Aksi', 'Detail'];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < logs.length; i++) {
        final log = logs[i];
        final rowIndex = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(rowIndex);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(log['time']),
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(log['user'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(log['action'] ?? '-');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(log['details'] ?? '-');
      }

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = "${title.replaceAll(' ', '_')}_$timestamp.xlsx";
        await saveFile(fileBytes, fileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengekspor $title ke Excel'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor data: $e'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> generateAdminLogsPdf({
    required BuildContext context,
    required List<Map<String, dynamic>> logs,
    String title = 'Log Aktivitas Sistem',
    Color? primaryColor,
    String brandingSuffix = 'Admin Dashboard',
  }) async {
    final themeColor = primaryColor ?? const Color(0xFF9333EA);
    final pdfThemeColor = PdfColor.fromInt(themeColor.toARGB32());
    
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.interRegular();
      final fontBold = await PdfGoogleFonts.interBold();

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Lapor FSM!',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: pdfThemeColor)),
                      pw.Text('Sistem Informasi Pelaporan Fasilitas',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: pdfThemeColor, thickness: 2),
              pw.SizedBox(height: 16),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Lapor FSM - $brandingSuffix',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['No', 'Waktu', 'Aksi', 'Detail', 'Oleh'],
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FixedColumnWidth(75),
                2: const pw.FixedColumnWidth(70),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FixedColumnWidth(60),
              },
              data: List.generate(logs.length, (index) {
                final log = logs[index];
                return [
                  (index + 1).toString(),
                  DateFormat('dd/MM HH:mm').format(log['time']),
                  log['action'] ?? '-',
                  log['details'] ?? '-',
                  log['user'] ?? '-',
                ];
              }),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: pdfThemeColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = "${title.replaceAll(' ', '_')}_$timestamp.pdf";
      
      await saveFile(bytes, fileName, 'application/pdf');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil mengunduh $fileName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF Log: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
