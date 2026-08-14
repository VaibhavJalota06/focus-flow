import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/focus_session_model.dart';

abstract class ITaskRepository {
  Future<List<TaskModel>> getTasks();
  Future<TaskModel?> getTaskById(String id);
  Future<void> insertTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);

  Future<List<SubtaskModel>> getSubtasksForTask(String taskId);
  Future<void> insertSubtask(SubtaskModel subtask);
  Future<void> updateSubtask(SubtaskModel subtask);
  Future<void> deleteSubtask(String id);

  Future<List<CategoryModel>> getCategories();
  Future<void> insertCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);

  Future<List<FocusSessionModel>> getFocusSessions();
  Future<void> insertFocusSession(FocusSessionModel session);

  Future<Map<String, dynamic>> exportAllData();
  Future<void> importAllData(Map<String, dynamic> data);
}

class TaskRepository implements ITaskRepository {
  final DatabaseHelper dbHelper;

  TaskRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<TaskModel>> getTasks() async {
    final db = await dbHelper.database;
    final maps = await db.query('tasks', orderBy: 'createdAt DESC');
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return TaskModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> insertTask(TaskModel task) async {
    final db = await dbHelper.database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final db = await dbHelper.database;
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await dbHelper.database;
    await db.delete('subtasks', where: 'taskId = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<SubtaskModel>> getSubtasksForTask(String taskId) async {
    final db = await dbHelper.database;
    final maps =
        await db.query('subtasks', where: 'taskId = ?', whereArgs: [taskId]);
    return maps.map((map) => SubtaskModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertSubtask(SubtaskModel subtask) async {
    final db = await dbHelper.database;
    await db.insert('subtasks', subtask.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateSubtask(SubtaskModel subtask) async {
    final db = await dbHelper.database;
    await db.update('subtasks', subtask.toMap(),
        where: 'id = ?', whereArgs: [subtask.id]);
  }

  @override
  Future<void> deleteSubtask(String id) async {
    final db = await dbHelper.database;
    await db.delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await dbHelper.database;
    final maps = await db.query('categories');
    if (maps.isEmpty) {
      return CategoryModel.defaultCategories;
    }
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertCategory(CategoryModel category) async {
    final db = await dbHelper.database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final db = await dbHelper.database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<FocusSessionModel>> getFocusSessions() async {
    final db = await dbHelper.database;
    final maps = await db.query('focus_sessions', orderBy: 'endedAt DESC');
    return maps.map((map) => FocusSessionModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertFocusSession(FocusSessionModel session) async {
    final db = await dbHelper.database;
    await db.insert('focus_sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    final tasks = await getTasks();
    final categories = await getCategories();
    final focusSessions = await getFocusSessions();
    return {
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'focusSessions': focusSessions.map((f) => f.toMap()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      if (data['tasks'] != null) {
        for (final item in data['tasks']) {
          await txn.insert('tasks', item as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['categories'] != null) {
        for (final item in data['categories']) {
          await txn.insert('categories', item as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['focusSessions'] != null) {
        for (final item in data['focusSessions']) {
          await txn.insert('focus_sessions', item as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
