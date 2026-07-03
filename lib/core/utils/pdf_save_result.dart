class PdfSaveResult {
  final String fileName;
  final String location;
  final bool downloaded;

  const PdfSaveResult({
    required this.fileName,
    required this.location,
    required this.downloaded,
  });
}
