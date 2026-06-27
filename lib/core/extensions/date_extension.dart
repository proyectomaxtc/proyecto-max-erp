extension DateExtension on DateTime {
  String get shortDate {
    return "${day.toString().padLeft(2, '0')}/"
        "${month.toString().padLeft(2, '0')}/"
        "$year";
  }

  String get shortTime {
    return "${hour.toString().padLeft(2, '0')}:"
        "${minute.toString().padLeft(2, '0')}";
  }

  String get fullDate {
    return "$shortDate $shortTime";
  }
}