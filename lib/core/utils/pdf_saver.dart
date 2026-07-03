import 'pdf_saver_io.dart'
    if (dart.library.html) 'pdf_saver_web.dart'
    as platform;
import 'pdf_save_result.dart';

Future<PdfSaveResult> savePdfBytes({
  required List<int> bytes,
  required String fileName,
  required String folderName,
}) {
  return platform.savePdfBytes(
    bytes: bytes,
    fileName: fileName,
    folderName: folderName,
  );
}
