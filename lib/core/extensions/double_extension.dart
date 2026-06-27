extension DoubleExtension on num {
  String get currency {
    return "\$ ${toStringAsFixed(0)}";
  }

  String get decimal {
    return toStringAsFixed(2);
  }

  String get percentage {
    return "${toStringAsFixed(1)} %";
  }
}