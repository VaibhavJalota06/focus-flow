import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../repositories/task_repository.dart';

final repositoryProvider = Provider<ITaskRepository>((ref) {
  return TaskRepository();
});

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final ITaskRepository _repository;

  CategoryNotifier(this._repository) : super(CategoryModel.defaultCategories) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final list = await _repository.getCategories();
    state = list;
  }

  Future<void> addCategory(CategoryModel category) async {
    await _repository.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return CategoryNotifier(repo);
});
