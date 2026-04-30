import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';

class DebtProvider extends ChangeNotifier {
  List<Debt> _debts = [];
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;

  List<Debt> get activeDebts => _debts.where((d) => !d.isPaid).toList();
  List<Debt> get settledDebts => _debts.where((d) => d.isPaid).toList();

  List<Debt> get iOwe =>
      activeDebts.where((d) => d.isOwedByMe).toList();

  List<Debt> get owedToMe =>
      activeDebts.where((d) => !d.isOwedByMe).toList();

  double get totalIOwe =>
      iOwe.fold(0, (sum, d) => sum + d.amount);

  double get totalOwedToMe =>
      owedToMe.fold(0, (sum, d) => sum + d.amount);

  double get netPosition => totalOwedToMe - totalIOwe;

  Debt? debtById(int? id) {
    if (id == null) return null;
    for (final d in _debts) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) async {
    return DatabaseHelper.instance.getDebtPayments(debtId);
  }

  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();
    _debts = await DatabaseHelper.instance.getAllDebts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDebt(Debt debt) async {
    final id = await DatabaseHelper.instance.insertDebt(debt);
    _debts.add(debt.copyWith(id: id));
    _sortDebts();
    notifyListeners();
  }

  void _sortDebts() {
    _debts.sort((a, b) => a.personName.compareTo(b.personName));
  }

  Future<void> updateDebt(Debt debt) async {
    await DatabaseHelper.instance.updateDebt(debt);
    final index = _debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) _debts[index] = debt;
    notifyListeners();
  }

  Future<void> deleteDebt(int id) async {
    await DatabaseHelper.instance.deleteDebt(id);
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> togglePaid(Debt debt) async {
    final updated = debt.copyWith(isPaid: !debt.isPaid);
    await updateDebt(updated);
  }

  Future<void> recordDebtPayment({
    required Debt debt,
    required double amount,
    required DateTime paidAt,
    required DebtPaymentKind kind,
    required String paymentMethod,
    String note = '',
    String externalRef = '',
  }) async {
    if (debt.id == null || amount <= 0) return;

    final payment = DebtPayment(
      debtId: debt.id!,
      paidAt: paidAt,
      amount: amount,
      kind: kind,
      paymentMethod: paymentMethod,
      note: note,
      externalRef: externalRef,
    );
    await DatabaseHelper.instance.insertDebtPayment(payment);

    final newBal = math.max(0.0, debt.amount - amount);
    final paidOff = newBal <= 0.009;

    await updateDebt(
      debt.copyWith(
        amount: newBal,
        isPaid: paidOff ? true : debt.isPaid,
      ),
    );
  }
}
