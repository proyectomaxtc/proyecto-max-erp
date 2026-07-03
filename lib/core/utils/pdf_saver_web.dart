// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'pdf_save_result.dart';

Future<PdfSaveResult> savePdfBytes({
  required List<int> bytes,
  required String fileName,
  required String folderName,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none'
    ..click();

  html.Url.revokeObjectUrl(url);

  return PdfSaveResult(
    fileName: fileName,
    location: 'Descargas del navegador',
    downloaded: true,
  );
}
