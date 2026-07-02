class ProductCodeGenerator {
  ProductCodeGenerator._();

  static final Map<String, String> _prefixes = {
    "cerraduras": "CER",
    "candados": "CAN",
    "llaves": "LLA",
    "yale": "YAL",
    "multipunto": "MUL",
    "cerrojos": "CRJ",
    "picaportes": "PIC",
    "bisagras": "BIS",
    "herrajes": "HER",
  };

  static String generate({
    required String categoria,
    required int numero,
  }) {
    final prefijo = _prefixes[
            categoria.trim().toLowerCase()] ??
        "PRD";

    final correlativo =
        numero.toString().padLeft(6, '0');

    return "$prefijo-$correlativo";
  }
}