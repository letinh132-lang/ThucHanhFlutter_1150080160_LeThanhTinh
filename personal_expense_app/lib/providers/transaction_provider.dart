import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  Database? _db;

  List<TransactionModel> get transactions => _transactions;

  Future<void> initDB() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = join(docs.path, 'transactions.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT, isIncome INTEGER)',
        );
      },
    );
    await loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_db == null) return;
    final data = await _db!.query('transactions', orderBy: 'date DESC');
    _transactions = data.map((e) => TransactionModel.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    if (_db == null) return;
    await _db!.insert('transactions', tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await loadTransactions();
  }
}
