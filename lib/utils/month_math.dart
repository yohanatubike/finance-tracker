/// Calendar-aware month addition (handles varying month lengths).
DateTime addCalendarMonths(DateTime date, int monthsToAdd) {
  final totalMonths = date.month - 1 + monthsToAdd;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day.clamp(1, lastDay);
  return DateTime(year, month, day);
}

/// Today normalized to date only for comparisons.
DateTime dateOnly(DateTime d) =>
    DateTime(d.year, d.month, d.day);
