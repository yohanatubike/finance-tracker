import 'package:flutter/foundation.dart';
import '../models/fund.dart';
import '../database/database_helper.dart';

class FundProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Fund> _funds = [];
  bool _isLoading = false;

  List<Fund> get funds => _funds;
  bool get isLoading => _isLoading;

  double get totalFunds {
    return _funds.fold(0.0, (sum, fund) => sum + fund.amount);
  }

  Future<void> loadFunds() async {
    _isLoading = true;
    notifyListeners();
    
    _funds = await _dbHelper.getAllFunds();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFund(Fund fund) async {
    final id = await _dbHelper.insertFund(fund);
    _funds.add(fund.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateFund(Fund fund) async {
    await _dbHelper.updateFund(fund);
    final index = _funds.indexWhere((f) => f.id == fund.id);
    if (index != -1) {
      _funds[index] = fund;
      notifyListeners();
    }
  }

  Future<void> deleteFund(int id) async {
    await _dbHelper.deleteFund(id);
    _funds.removeWhere((fund) => fund.id == id);
    notifyListeners();
  }

  Future<void> updateFundAmount(int fundId, double newAmount) async {
    final fund = _funds.firstWhere((f) => f.id == fundId);
    final updatedFund = fund.copyWith(amount: newAmount);
    await updateFund(updatedFund);
  }

  Fund? getFundById(int id) {
    try {
      return _funds.firstWhere((fund) => fund.id == id);
    } catch (e) {
      return null;
    }
  }
}
