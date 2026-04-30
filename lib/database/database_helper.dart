import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fund.dart';
import '../models/asset.dart';
import '../models/incoming_payment.dart';
import '../models/outgoing_payment.dart';
import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../models/stock.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('personal_finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE funds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incoming_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        targetFundId INTEGER NOT NULL,
        ledgerNote TEXT NOT NULL DEFAULT '',
        externalRef TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (targetFundId) REFERENCES funds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE outgoing_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        sourceFundId INTEGER NOT NULL,
        deadlineAt TEXT,
        ledgerNote TEXT NOT NULL DEFAULT '',
        externalRef TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (sourceFundId) REFERENCES funds (id) ON DELETE CASCADE
      )
    ''');

    await _createDebtsTable(db);
    await _createDebtPaymentsTable(db);
    await _createStocksTable(db);
    await _createTickerPricesTable(db);
    await _createUserTickersTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDebtsTable(db);
      await _createDebtPaymentsTable(db);
    }
    if (oldVersion < 3) {
      await _createStocksTable(db);
    }
    if (oldVersion < 4) {
      await _createUserTickersTable(db);
    }
    if (oldVersion < 5) {
      await _createTickerPricesTable(db);
      await db.execute('''
        INSERT INTO ticker_prices (ticker, currentPrice)
        SELECT UPPER(ticker), MAX(currentPrice) FROM stocks GROUP BY UPPER(ticker)
      ''');
    }
    if (oldVersion < 6) {
      await db.execute(
          'ALTER TABLE debts ADD COLUMN monthlyInstallment REAL');
      await db.execute('ALTER TABLE debts ADD COLUMN loanStartDate TEXT');
      await db.execute(
          'ALTER TABLE debts ADD COLUMN defaultPaymentMethod TEXT NOT NULL DEFAULT \'\'');
      await db.execute(
          'ALTER TABLE debts ADD COLUMN hasInstallmentSchedule INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE debts ADD COLUMN originalPrincipal REAL');
      await db.execute(
          'UPDATE debts SET originalPrincipal = amount WHERE originalPrincipal IS NULL');
      await _createDebtPaymentsTable(db);
    }
    if (oldVersion < 7) {
      await db.execute(
          'ALTER TABLE outgoing_payments ADD COLUMN deadlineAt TEXT');
    }
    if (oldVersion < 8) {
      await db.execute(
          'ALTER TABLE stocks ADD COLUMN isWatchlist INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 9) {
      await db.execute(
          'ALTER TABLE incoming_payments ADD COLUMN ledgerNote TEXT NOT NULL DEFAULT \'\'');
      await db.execute(
          'ALTER TABLE incoming_payments ADD COLUMN externalRef TEXT NOT NULL DEFAULT \'\'');
      await db.execute(
          'ALTER TABLE outgoing_payments ADD COLUMN ledgerNote TEXT NOT NULL DEFAULT \'\'');
      await db.execute(
          'ALTER TABLE outgoing_payments ADD COLUMN externalRef TEXT NOT NULL DEFAULT \'\'');
      await db.execute(
          'ALTER TABLE debt_payments ADD COLUMN externalRef TEXT NOT NULL DEFAULT \'\'');
    }
  }

  Future<void> _createDebtsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personName TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        isOwedByMe INTEGER NOT NULL DEFAULT 0,
        isPaid INTEGER NOT NULL DEFAULT 0,
        monthlyInstallment REAL,
        loanStartDate TEXT,
        defaultPaymentMethod TEXT NOT NULL DEFAULT '',
        hasInstallmentSchedule INTEGER NOT NULL DEFAULT 0,
        originalPrincipal REAL NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createDebtPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        paidAt TEXT NOT NULL,
        amount REAL NOT NULL,
        kind TEXT NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT '',
        externalRef TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments(debtId)');
  }

  Future<int> insertFund(Fund fund) async {
    final db = await database;
    return await db.insert('funds', fund.toMap());
  }

  Future<List<Fund>> getAllFunds() async {
    final db = await database;
    final result = await db.query('funds', orderBy: 'name ASC');
    return result.map((map) => Fund.fromMap(map)).toList();
  }

  Future<Fund?> getFund(int id) async {
    final db = await database;
    final result = await db.query('funds', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Fund.fromMap(result.first);
  }

  Future<int> updateFund(Fund fund) async {
    final db = await database;
    return await db.update(
      'funds',
      fund.toMap(),
      where: 'id = ?',
      whereArgs: [fund.id],
    );
  }

  Future<int> deleteFund(int id) async {
    final db = await database;
    return await db.delete('funds', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertAsset(Asset asset) async {
    final db = await database;
    return await db.insert('assets', asset.toMap());
  }

  Future<List<Asset>> getAllAssets() async {
    final db = await database;
    final result = await db.query('assets', orderBy: 'name ASC');
    return result.map((map) => Asset.fromMap(map)).toList();
  }

  Future<int> updateAsset(Asset asset) async {
    final db = await database;
    return await db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<int> deleteAsset(int id) async {
    final db = await database;
    return await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertIncomingPayment(IncomingPayment payment) async {
    final db = await database;
    return await db.insert('incoming_payments', payment.toMap());
  }

  Future<List<IncomingPayment>> getAllIncomingPayments() async {
    final db = await database;
    final result = await db.query('incoming_payments', orderBy: 'name ASC');
    return result.map((map) => IncomingPayment.fromMap(map)).toList();
  }

  Future<int> updateIncomingPayment(IncomingPayment payment) async {
    final db = await database;
    return await db.update(
      'incoming_payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deleteIncomingPayment(int id) async {
    final db = await database;
    return await db.delete('incoming_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertOutgoingPayment(OutgoingPayment payment) async {
    final db = await database;
    return await db.insert('outgoing_payments', payment.toMap());
  }

  Future<List<OutgoingPayment>> getAllOutgoingPayments() async {
    final db = await database;
    final result = await db.query('outgoing_payments', orderBy: 'name ASC');
    return result.map((map) => OutgoingPayment.fromMap(map)).toList();
  }

  Future<int> updateOutgoingPayment(OutgoingPayment payment) async {
    final db = await database;
    return await db.update(
      'outgoing_payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deleteOutgoingPayment(int id) async {
    final db = await database;
    return await db.delete('outgoing_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _createStocksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticker TEXT NOT NULL,
        companyName TEXT NOT NULL,
        shares INTEGER NOT NULL,
        buyPrice REAL NOT NULL,
        currentPrice REAL NOT NULL DEFAULT 0,
        isWatchlist INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createTickerPricesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ticker_prices (
        ticker TEXT PRIMARY KEY NOT NULL,
        currentPrice REAL NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createUserTickersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_tickers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticker TEXT NOT NULL,
        companyName TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertUserTicker(String ticker, String companyName) async {
    final db = await database;
    return await db.insert('user_tickers', {
      'ticker': ticker,
      'companyName': companyName,
    });
  }

  Future<List<Map<String, dynamic>>> getAllUserTickers() async {
    final db = await database;
    return await db.query('user_tickers', orderBy: 'ticker ASC');
  }

  Future<int> deleteUserTicker(int id) async {
    final db = await database;
    return await db.delete('user_tickers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertStock(Stock stock) async {
    final db = await database;
    return await db.insert('stocks', stock.toMap());
  }

  Future<List<Stock>> getAllStocks() async {
    final db = await database;
    final priceRows = await db.query('ticker_prices');
    final priceByTicker = {
      for (final r in priceRows)
        (r['ticker'] as String).toUpperCase():
            (r['currentPrice'] as num).toDouble(),
    };
    final result = await db.query('stocks', orderBy: 'ticker ASC');
    return result.map((map) {
      final ticker = map['ticker'] as String;
      final merged = priceByTicker[ticker.toUpperCase()] ??
          (map['currentPrice'] as num).toDouble();
      return Stock.fromMap({...map, 'currentPrice': merged});
    }).toList();
  }

  Future<void> upsertTickerPrices(Map<String, double> tickerToPrice) async {
    if (tickerToPrice.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final e in tickerToPrice.entries) {
      batch.insert(
        'ticker_prices',
        {'ticker': e.key.toUpperCase(), 'currentPrice': e.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateStock(Stock stock) async {
    final db = await database;
    return await db.update(
      'stocks',
      stock.toMap(),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  Future<int> deleteStock(int id) async {
    final db = await database;
    return await db.delete('stocks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<Debt>> getAllDebts() async {
    final db = await database;
    final result = await db.query('debts', orderBy: 'personName ASC');
    return result.map((map) => Debt.fromMap(map)).toList();
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDebtPayment(DebtPayment payment) async {
    final db = await database;
    return await db.insert('debt_payments', payment.toMap());
  }

  Future<List<DebtPayment>> getDebtPayments(int debtId) async {
    final db = await database;
    final rows = await db.query(
      'debt_payments',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'paidAt DESC',
    );
    return rows.map((map) => DebtPayment.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
