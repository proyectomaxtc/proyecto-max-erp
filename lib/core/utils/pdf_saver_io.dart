import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'pdf_save_result.dart';

Future<PdfSaveResult> savePdfBytes({
  required List<int> bytes,
  required String fileName,
  required String folderName,
}) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(appDir.path, 'proyecto_max', folderName));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes);

  return PdfSaveResult(
    fileName: fileName,
    location: dir.path,
    downloaded: false,
  );
}
