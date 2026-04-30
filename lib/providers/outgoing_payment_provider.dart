import 'package:flutter/foundation.dart';
import '../models/outgoing_payment.dart';
import '../database/database_helper.dart';
import '../providers/fund_provider.dart';

class OutgoingPaymentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FundProvider _fundProvider;
  List<OutgoingPayment> _payments = [];
  bool _isLoading = false;

  OutgoingPaymentProvider(this._fundProvider);

  List<OutgoingPayment> get payments => _payments;
  bool get isLoading => _isLoading;

  List<OutgoingPayment> get pendingPayments {
    final list = _payments.where((p) => !p.isCompleted).toList();
    list.sort((a, b) {
      final dA = a.deadlineAt;
      final dB = b.deadlineAt;
      if (dA == null && dB == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (dA == null) return 1;
      if (dB == null) return -1;
      final byTime = dA.compareTo(dB);
      if (byTime != 0) return byTime;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  double get totalPending {
    return pendingPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();
    
    _payments = await _dbHelper.getAllOutgoingPayments();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPayment(OutgoingPayment payment) async {
    final id = await _dbHelper.insertOutgoingPayment(payment);
    _payments.add(payment.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updatePayment(OutgoingPayment payment) async {
    await _dbHelper.updateOutgoingPayment(payment);
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      _payments[index] = payment;
      notifyListeners();
    }
  }

  Future<void> deletePayment(int id) async {
    await _dbHelper.deleteOutgoingPayment(id);
    _payments.removeWhere((payment) => payment.id == id);
    notifyListeners();
  }

  Future<void> toggleCompletion(OutgoingPayment payment) async {
    final fund = _fundProvider.getFundById(payment.sourceFundId);
    if (fund == null) return;

    final newCompletionStatus = !payment.isCompleted;
    final updatedPayment = payment.copyWith(
      isCompleted: newCompletionStatus,
      ledgerNote: newCompletionStatus ? payment.ledgerNote : '',
      externalRef: newCompletionStatus ? payment.externalRef : '',
    );

    final newFundAmount = newCompletionStatus
        ? fund.amount - payment.amount
        : fund.amount + payment.amount;

    await _dbHelper.updateOutgoingPayment(updatedPayment);
    await _fundProvider.updateFundAmount(fund.id!, newFundAmount);
    
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      _payments[index] = updatedPayment;
      notifyListeners();
    }
  }
}
