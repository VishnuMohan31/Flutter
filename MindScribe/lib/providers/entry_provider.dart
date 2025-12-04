// Entry Provider - Manages state for all entries
// This is the bridge between UI and Database

import 'package:flutter/material.dart';
import '../models/entry_model.dart';
import '../models/reminder_model.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class EntryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<EntryModel> _entries = [];
  List<EntryModel> _filteredEntries = [];
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedType;
  String? _selectedPriority;
  String? _selectedStatus;

  // Getters
  List<EntryModel> get entries => _filteredEntries;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedType => _selectedType;

  // Initialize - load all entries
  Future<void> initialize() async {
    await loadEntries();
  }

  // Load all entries from database
  Future<void> loadEntries() async {
    _entries = await _db.getAllEntries();
    _applyFilters();
    notifyListeners();
  }

  // Add new entry
  Future<void> addEntry(EntryModel entry, List<Reminder>? reminders) async {
    try {
      await _db.createEntry(entry);
      print('✅ Entry created: ${entry.title}');
      
      // Schedule notifications if reminders exist
      if (reminders != null && reminders.isNotEmpty) {
        print('📅 Creating ${reminders.length} reminder(s)...');
        final createdReminders = <Reminder>[];
        
        for (var reminder in reminders) {
          final created = await _db.createReminder(reminder);
          createdReminders.add(created);
        }
        
        // Schedule notifications with the created reminders (which have IDs)
        await _notifications.scheduleMultipleReminders(entry, createdReminders);
        print('✅ ${createdReminders.length} notification(s) scheduled');
      }
      
      await loadEntries();
    } catch (e) {
      print('❌ Error adding entry: $e');
      rethrow;
    }
  }

  // Update entry
  Future<void> updateEntry(EntryModel entry, List<Reminder>? reminders) async {
    try {
      await _db.updateEntry(entry);
      print('✅ Entry updated: ${entry.title}');
      
      // Update reminders
      if (reminders != null) {
        // Delete old reminders and their notifications
        final oldReminders = await _db.getRemindersForEntry(entry.id);
        for (var reminder in oldReminders) {
          if (reminder.id != null) {
            await _notifications.cancelNotification(reminder.id!);
          }
        }
        await _db.deleteRemindersForEntry(entry.id);
        print('🗑️ Old reminders deleted');
        
        // Add new reminders
        final createdReminders = <Reminder>[];
        for (var reminder in reminders) {
          final created = await _db.createReminder(reminder);
          createdReminders.add(created);
          print('   New reminder created for: ${reminder.reminderTime}');
        }
        
        // Reschedule notifications
        await _notifications.scheduleMultipleReminders(entry, createdReminders);
        print('✅ All notifications rescheduled');
      }
      
      await loadEntries();
    } catch (e) {
      print('❌ Error updating entry: $e');
      rethrow;
    }
  }

  // Delete entry
  Future<void> deleteEntry(String id) async {
    try {
      print('🗑️ Deleting entry: $id');
      
      // Get reminders to cancel notifications
      try {
        final reminders = await _db.getRemindersForEntry(id);
        for (var reminder in reminders) {
          if (reminder.id != null && reminder.id! > 0) {
            try {
              await _notifications.cancelNotification(reminder.id!);
              print('   Cancelled notification: ${reminder.id}');
            } catch (e) {
              print('   Warning: Could not cancel notification ${reminder.id}: $e');
              // Continue even if notification cancellation fails
            }
          }
        }
      } catch (e) {
        print('   Warning: Could not get reminders: $e');
        // Continue even if getting reminders fails
      }
      
      // Delete the entry regardless of notification cancellation
      await _db.deleteEntry(id);
      print('✅ Entry deleted successfully');
      
      await loadEntries();
    } catch (e) {
      print('❌ Error deleting entry: $e');
      rethrow;
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(EntryModel entry) async {
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);
    await updateEntry(updated, null);
  }

  // Mark task as complete
  Future<void> markAsComplete(EntryModel entry) async {
    final updated = entry.copyWith(
      status: 'completed',
      progress: 100,
    );
    await updateEntry(updated, null);
  }

  // Search entries
  void searchEntries(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  // Filter by type
  void filterByType(String? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  // Filter by priority
  void filterByPriority(String? priority) {
    _selectedPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedType = null;
    _selectedPriority = null;
    _selectedStatus = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = entry.title.toLowerCase().contains(_searchQuery) ||
            entry.content.toLowerCase().contains(_searchQuery) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        if (!matchesSearch) return false;
      }

      // Category filter
      if (_selectedCategoryId != null && entry.categoryId != _selectedCategoryId) {
        return false;
      }

      // Type filter
      if (_selectedType != null && entry.type != _selectedType) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != null && entry.priority != _selectedPriority) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null && entry.status != _selectedStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  // Get entries for specific date (for calendar)
  List<EntryModel> getEntriesForDate(DateTime date) {
    return _entries.where((entry) {
      if (entry.eventDate == null) return false;
      return entry.eventDate!.year == date.year &&
          entry.eventDate!.month == date.month &&
          entry.eventDate!.day == date.day;
    }).toList();
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    return await _db.getStatistics();
  }

  // Get reminders for entry
  Future<List<Reminder>> getRemindersForEntry(String entryId) async {
    return await _db.getRemindersForEntry(entryId);
  }
}
