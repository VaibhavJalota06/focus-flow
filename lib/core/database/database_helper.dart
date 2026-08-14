import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('focus_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE tasks ADD COLUMN subtasks_json TEXT');
        } catch (_) {}
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id $textType PRIMARY KEY,
        title $textType,
        description $textType,
        date $textType,
        startTime $textTypeNullable,
        dueTime $textTypeNullable,
        priority $textType,
        categoryId $textType,
        isCompleted $integerType,
        completedAt $textTypeNullable,
        recurrenceRule $textTypeNullable,
        reminderTime $textTypeNullable,
        notes $textTypeNullable,
        isInbox $integerType,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id $textType PRIMARY KEY,
        name $textType,
        iconCodePoint $integerType,
        colorValue $integerType,
        isDefault $integerType
      )
    ''');

    // Subtasks table
    await db.execute('''
      CREATE TABLE subtasks (
        id $textType PRIMARY KEY,
        taskId $textType,
        title $textType,
        isCompleted $integerType,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Focus Sessions table
    await db.execute('''
      CREATE TABLE focus_sessions (
        id $textType PRIMARY KEY,
        taskId $textTypeNullable,
        taskTitle $textType,
        durationMinutes $integerType,
        completed $integerType,
        startedAt $textType,
        endedAt $textType
      )
    ''');

    // Populate default categories
    for (final category in CategoryModel.defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
