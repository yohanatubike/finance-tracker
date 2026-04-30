import 'package:flutter/foundation.dart';
import '../models/incoming_payment.dart';
import '../database/database_helper.dart';
import '../providers/fund_provider.dart';

class IncomingPaymentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FundProvider _fundProvider;
  List<IncomingPayment> _payments = [];
  bool _isLoading = false;

  IncomingPaymentProvider(this._fundProvider);

  List<IncomingPayment> get payments => _payments;
  bool get isLoading => _isLoading;

  List<IncomingPayment> get pendingPayments {
    return _payments.where((p) => !p.isCompleted).toList();
  }

  double get totalPending {
    return pendingPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();
    
    _payments = await _dbHelper.getAllIncomingPayments();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPayment(IncomingPayment payment) async {
    final id = await _dbHelper.insertIncomingPayment(payment);
    _payments.add(payment.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updatePayment(IncomingPayment payment) async {
    await _dbHelper.updateIncomingPayment(payment);
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      _payments[index] = payment;
      notifyListeners();
    }
  }

  Future<void> deletePayment(int id) async {
    await _dbHelper.deleteIncomingPayment(id);
    _payments.removeWhere((payment) => payment.id == id);
    notifyListeners();
  }

  Future<void> toggleCompletion(IncomingPayment payment) async {
    final fund = _fundProvider.getFundById(payment.targetFundId);
    if (fund == null) return;

    final newCompletionStatus = !payment.isCompleted;
    final updatedPayment = payment.copyWith(
      isCompleted: newCompletionStatus,
      ledgerNote: newCompletionStatus ? payment.ledgerNote : '',
      externalRef: newCompletionStatus ? payment.externalRef : '',
    );

    final newFundAmount = newCompletionStatus
        ? fund.amount + payment.amount
        : fund.amount - payment.amount;

    await _dbHelper.updateIncomingPayment(updatedPayment);
    await _fundProvider.updateFundAmount(fund.id!, newFundAmount);
    
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      _payments[index] = updatedPayment;
      notifyListeners();
    }
  }
}
