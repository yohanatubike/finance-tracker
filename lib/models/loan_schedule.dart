import 'package:intl/intl.dart';

import '../utils/date_window.dart';
import '../utils/month_math.dart';
import 'debt.dart';

/// One projected row for the payment schedule UI.
class LoanScheduleRow {
  final DateTime dueDate;
  final double paymentAmount;
  final double remainingAfter;

  const LoanScheduleRow({
    required this.dueDate,
    required this.paymentAmount,
    required this.remainingAfter,
  });
}

class LoanScheduleCalculator {
  LoanScheduleCalculator._();

  /// Upcoming installments from **today**, using current balance and monthly amount.
  static List<LoanScheduleRow> remainingSchedule({
    required Debt debt,
    int maxRows = 24,
  }) {
    if (!debt.hasLoanScheduleData) return [];

    final monthly = debt.monthlyInstallment!;
    final start = debt.loanStartDate!;
    var remaining = debt.amount;
    final today = dateOnly(DateTime.now());

    var i = 1;
    DateTime? firstDueOnOrAfterToday;
    while (i < 600) {
      final due = addCalendarMonths(start, i);
      if (!dateOnly(due).isBefore(today)) {
        firstDueOnOrAfterToday = due;
        break;
      }
      i++;
    }
    firstDueOnOrAfterToday ??= addCalendarMonths(start, 1);

    final rows = <LoanScheduleRow>[];
    var dueCursor = firstDueOnOrAfterToday;
    for (var k = 0; k < maxRows && remaining > 0.009; k++) {
      final pay = monthly > remaining ? remaining : monthly;
      remaining -= pay;
      rows.add(LoanScheduleRow(
        dueDate: dueCursor,
        paymentAmount: pay,
        remainingAfter: remaining < 0 ? 0 : remaining,
      ));
      dueCursor = addCalendarMonths(dueCursor, 1);
    }
    return rows;
  }

  /// If the full original amount were cleared in equal monthly chunks from start.
  static DateTime? originalTermEnd(Debt debt) {
    if (!debt.hasLoanScheduleData || debt.originalPrincipal <= 0) return null;
    final m = debt.monthlyInstallment!;
    if (m <= 0) return null;
    final n = (debt.originalPrincipal / m).ceil();
    return addCalendarMonths(debt.loanStartDate!, n);
  }

  /// Approximate payoff date from **current** balance (monthly cadence forward from today).
  static DateTime? payoffFromRemaining({
    required double remainingBalance,
    required double monthlyInstallment,
  }) {
    if (monthlyInstallment <= 0 || remainingBalance <= 0.009) return null;
    final monthsLeft = (remainingBalance / monthlyInstallment).ceil();
    return addCalendarMonths(dateOnly(DateTime.now()), monthsLeft);
  }

  static String formatDue(DateTime d) => DateFormat.yMMMd().format(d);

  /// Active “I owe” loans with an installment due in the next 7 days (incl. today).
  static List<({Debt debt, LoanScheduleRow row})> installmentsDueNextWeek(
    Iterable<Debt> debts,
    DateTime now,
  ) {
    final list = <({Debt debt, LoanScheduleRow row})>[];
    for (final debt in debts) {
      if (debt.isPaid || !debt.isOwedByMe || !debt.hasLoanScheduleData) {
        continue;
      }
      final rows = remainingSchedule(debt: debt, maxRows: 48);
      for (final r in rows) {
        if (isWithinNextSevenDays(r.dueDate, now)) {
          list.add((debt: debt, row: r));
        }
      }
    }
    list.sort((a, b) => a.row.dueDate.compareTo(b.row.dueDate));
    return list;
  }
}
