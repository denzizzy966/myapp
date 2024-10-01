import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'transaction.dart' as transactionmodel;

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._();

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    String dbPath = path.join(databasesPath, 'finance_database.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, amount REAL, isExpense INTEGER, date TEXT)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN date TEXT');
        }
      },
    );
  }

  Future<int> insertTransaction(transactionmodel.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<transactionmodel.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    print('DatabaseHelper - Raw query result: $maps');
    final result = List<transactionmodel.Transaction>.from(maps.map((map) {
      print('DatabaseHelper - Processing map: $map');
      return transactionmodel.Transaction.fromMap(map);
    }));
    print(
        'DatabaseHelper - getTransactions result type: ${result.runtimeType}');
    if (result.isNotEmpty) {
      print('DatabaseHelper - First item type: ${result.first.runtimeType}');
      print('DatabaseHelper - First item content: ${result.first.toMap()}');
    }
    return result;
  }
  

  Future<int> updateTransaction(transactionmodel.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
