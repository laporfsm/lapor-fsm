import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves and shares a file on native platforms (Android/iOS/Desktop)
Future<void> saveAndShareFileNative(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles([
    XFile(file.path, mimeType: mimeType),
  ], text: 'Export Laporan FSM');
}

/// Downloads a file - stub for web (not used on native)
Future<void> downloadFileWeb(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  // This implementation is used on native platforms
  // On web, the web-specific version will be used instead
  throw UnsupportedError(
    'downloadFileWeb should only be called on web platform',
  );
}
