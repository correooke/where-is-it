import 'dart:async';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  // Singleton instance
  static final AppDatabase instance = AppDatabase._();
  static const _dbName = 'app.db';
  Database? _database;

  AppDatabase._();

  /// Opens the database (if not already open) and returns it
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final dbPath = join(dir.path, _dbName);
    return await databaseFactoryIo.openDatabase(dbPath);
  }
}
