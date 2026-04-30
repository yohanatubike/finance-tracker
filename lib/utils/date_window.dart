import 'package:flutter/material.dart';

/// True if [date] falls on a calendar day in \[[startOfToday], [startOfToday]+7 days)\ — i.e. next 7 days including today.
bool isWithinNextSevenDays(DateTime date, DateTime now) {
  final d = DateUtils.dateOnly(date);
  final start = DateUtils.dateOnly(now);
  final end = start.add(const Duration(days: 7));
  return !d.isBefore(start) && d.isBefore(end);
}
