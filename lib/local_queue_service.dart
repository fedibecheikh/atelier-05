import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Persistance locale de la file d'attente (SQLite).
///
/// Les clients sont enregistrés immédiatement sur le téléphone, puis marqués
/// `is_synced = 1` lorsqu'ils ont été envoyés à Supabase.
class LocalQueueService {
  LocalQueueService({bool inMemory = false}) : _inMemory = inMemory;

  static const String tableName = 'local_clients';

  final bool _inMemory;
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    if (_inMemory) {
      return openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _onCreate,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'waiting_room.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL,
        lng REAL,
        accuracy_m REAL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> insertClientLocally(Map<String, dynamic> client) async {
    final db = await database;
    await db.insert(
      tableName,
      client,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    return db.query(tableName, orderBy: 'created_at ASC, id ASC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedClients() async {
    final db = await database;
    return db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC, id ASC',
    );
  }

  Future<void> markClientAsSynced(String id) async {
    final db = await database;
    await db.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
