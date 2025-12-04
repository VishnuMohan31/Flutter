// Category Provider - Manages state for categories

import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../database/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Category> _categories = [];

  // Getter
  List<Category> get categories => _categories;

  // Initialize - load all categories
  Future<void> initialize() async {
    await loadCategories();
  }

  // Load all categories
  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  // Add new category
  Future<void> addCategory(Category category) async {
    await _db.createCategory(category);
    await loadCategories();
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  // Delete category
  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  // Get category by ID
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category color
  Color getCategoryColor(int? categoryId) {
    if (categoryId == null) return Colors.grey;
    final category = getCategoryById(categoryId);
    if (category == null) return Colors.grey;
    return Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));
  }
}
