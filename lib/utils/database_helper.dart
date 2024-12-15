import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // 初始化 FFI
    if (Platform.isWindows || Platform.isLinux) {
      // 在 Windows 或 Linux 上初始化 sqflite_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    print('数据库路径: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        duration INTEGER NOT NULL
      )
    ''');
    
    // 添加未完成任务表
    await db.execute('''
      CREATE TABLE unfinished_task(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTask(String name, DateTime startTime, DateTime endTime) async {
    final db = await database;
    final duration = endTime.difference(startTime).inMinutes;

    final data = {
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
    };

    return await db.insert('tasks', data);
  }

  Future<List<Map<String, dynamic>>> getTodayTasks() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return await db.query(
      'tasks',
      where: 'startTime BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'startTime ASC',
    );
  }

  // 保存未完成任务
  Future<void> saveUnfinishedTask(String name, DateTime startTime) async {
    final db = await database;
    // 先清除之前的未完成任务
    await db.delete('unfinished_task');
    // 保存新的未完成任务
    await db.insert('unfinished_task', {
      'name': name,
      'startTime': startTime.toIso8601String(),
    });
  }

  // 获取未完成任务
  Future<Map<String, dynamic>?> getUnfinishedTask() async {
    final db = await database;
    final results = await db.query('unfinished_task');
    if (results.isEmpty) return null;
    return results.first;
  }

  // 清除未完成任务
  Future<void> clearUnfinishedTask() async {
    final db = await database;
    await db.delete('unfinished_task');
  }

  Future<List<Map<String, dynamic>>> getDayTasks(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return await db.query(
      'tasks',
      where: 'startTime BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'startTime ASC',
    );
  }
} 