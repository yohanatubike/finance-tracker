import '../models/fund.dart';
import '../models/asset.dart';
import '../models/incoming_payment.dart';
import '../models/outgoing_payment.dart';
import '../models/debt.dart';
import 'database_helper.dart';

class DatabaseSeeder {
  static Future<void> seedDatabase() async {
    final dbHelper = DatabaseHelper.instance;

    final funds = await dbHelper.getAllFunds();
    if (funds.isNotEmpty) {
      return;
    }

    await _seedFunds(dbHelper);
    await _seedAssets(dbHelper);
    await _seedIncomingPayments(dbHelper);
    await _seedOutgoingPayments(dbHelper);
    await _seedDebts(dbHelper);
  }

  static Future<void> _seedFunds(DatabaseHelper dbHelper) async {
    final funds = [
      Fund(
        name: 'Selcom',
        description: 'Selcom account',
        amount: 905665,
      ),
      Fund(
        name: 'CRDB 1',
        description: 'CRDB Bank Account 1',
        amount: 60000,
      ),
      Fund(
        name: 'CRDB 2',
        description: 'CRDB Bank Account 2',
        amount: 46072,
      ),
      Fund(
        name: 'M1xx',
        description: 'M1xx account',
        amount: 2662,
      ),
      Fund(
        name: 'M-Pesa',
        description: 'M-Pesa mobile money',
        amount: 16351,
      ),
      Fund(
        name: 'Wallet',
        description: 'Wallet money',
        amount: 4351,
      ),
    ];

    for (var fund in funds) {
      await dbHelper.insertFund(fund);
    }
  }

  static Future<void> _seedAssets(DatabaseHelper dbHelper) async {
    final assets = [
      Asset(
        name: 'Puna Plot',
        description: 'Puna plot property',
        amount: 80000000,
      ),
      Asset(
        name: 'Ungidoni House',
        description: 'Unguidoni house property',
        amount: 80000000,
      ),
      Asset(
        name: 'Sanga Sanga Plot',
        description: 'Samyn Sanga plot property',
        amount: 5000000,
      ),
      Asset(
        name: 'VW Golf Car',
        description: 'Volkswagen Golf car',
        amount: 10000000,
      ),
    ];

    for (var asset in assets) {
      await dbHelper.insertAsset(asset);
    }
  }

  static Future<void> _seedIncomingPayments(DatabaseHelper dbHelper) async {
    final funds = await dbHelper.getAllFunds();
    if (funds.isEmpty) return;

    final selcomFund = funds.firstWhere((f) => f.name == 'Selcom');
    final crdb1Fund = funds.firstWhere((f) => f.name == 'CRDB 1');

    final incomingPayments = [
      IncomingPayment(
        name: 'DCS April',
        description: 'DCS March payment',
        amount: 3200000,
        isCompleted: false,
        targetFundId: selcomFund.id!,
      )
    ];

    for (var payment in incomingPayments) {
      await dbHelper.insertIncomingPayment(payment);
    }
  }

  static Future<void> _seedOutgoingPayments(DatabaseHelper dbHelper) async {
    final funds = await dbHelper.getAllFunds();
    if (funds.isEmpty) return;

    final selcomFund = funds.firstWhere((f) => f.name == 'Selcom');

    final outgoingPayments = [
      OutgoingPayment(
        name: 'Ivan Wedding',
        description: 'Ivan Wedding payment',
        amount: 200000,
        isCompleted: false,
        sourceFundId: selcomFund.id!,
        deadlineAt: DateTime(2026, 5, 15, 14, 30),
      ),
    ];

    for (var payment in outgoingPayments) {
      await dbHelper.insertOutgoingPayment(payment);
    }
  }

  static Future<void> _seedDebts(DatabaseHelper dbHelper) async {
    final existing = await dbHelper.getAllDebts();
    if (existing.isNotEmpty) return;

    final debts = [
      Debt(
        personName: 'Summatra Saccos',
        description: 'Summatra Saccos loan repayment',
        amount: 36000000,
        isOwedByMe: false,
      ),
    ];

    for (var debt in debts) {
      await dbHelper.insertDebt(debt);
    }
  }
}
