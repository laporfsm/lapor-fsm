// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Downloads a file in web browsers by creating a Blob and triggering download
Future<void> downloadFileWeb(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();

  // Clean up
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

/// Stub for native file sharing - not used on web
Future<void> saveAndShareFileNative(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  // On web, this function should never be called
  // The kIsWeb check in the caller prevents this
  throw UnsupportedError(
    'saveAndShareFileNative is not supported on web platform',
  );
}
