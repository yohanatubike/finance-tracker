import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';

/// Currency formatter using Profile → currency symbol (default TZS).
NumberFormat currencyFormat(BuildContext context) {
  final sym =
      context.watch<ProfileProvider>().profile.effectiveCurrencySymbol;
  return NumberFormat.currency(symbol: sym, decimalDigits: 0);
}

/// For dialogs/snackbars where watch isn't available — pass profile explicitly.
NumberFormat currencyFormatForProfile(ProfileProvider profile) {
  return NumberFormat.currency(
    symbol: profile.profile.effectiveCurrencySymbol,
    decimalDigits: 0,
  );
}

/// Prefix for amount fields (e.g. `TZS `).
String currencyPrefix(BuildContext context) {
  return context.watch<ProfileProvider>().profile.effectiveCurrencySymbol;
}

/// Date + time for deadlines / reminders respecting 12h vs 24h preference.
String formatAppDateTime(DateTime d, BuildContext context) {
  final use24 =
      context.watch<ProfileProvider>().profile.use24HourTime;
  final datePart = DateFormat('EEE, MMM d').format(d);
  final timePart =
      use24 ? DateFormat.Hm().format(d) : DateFormat.jm().format(d);
  return '$datePart · $timePart';
}
