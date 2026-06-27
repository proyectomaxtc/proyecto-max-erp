extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;

    return "${this[0].toUpperCase()}${substring(1)}";
  }

  bool get isEmail {
    return RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    ).hasMatch(this);
  }
}