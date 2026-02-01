import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:mobile/core/services/api_service.dart';

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
        backgroundColorHex: ExcelColor.fromHexString('#059669'), // Emerald Green
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
        'Darurat'
      ];

      // Add Headers
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add Data
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

      // Finalize file
      // Use encode() instead of save() to get bytes without triggering library's auto-download
      final fileBytes = excel.encode();

      if (kIsWeb && fileBytes != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "${title.replaceAll(' ', '_')}_$timestamp.xlsx")
          ..style.display = 'none';
        
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
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

      if (kIsWeb) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final blob = html.Blob([response.data], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "${title.replaceAll(' ', '_')}_$timestamp.pdf")
          ..style.display = 'none';
          
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      }

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
}
