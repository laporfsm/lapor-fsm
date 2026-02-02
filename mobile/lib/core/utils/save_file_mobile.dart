import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(List<int> bytes, String fileName, String mimeType) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('File saved at ${file.path}');
  } catch (e) {
    debugPrint('Error saving file: $e');
  }
}
