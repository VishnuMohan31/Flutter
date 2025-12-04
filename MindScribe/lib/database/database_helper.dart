// Database Helper - Manages SQLite database operations
// This is the BRAIN of our data storage system

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry_model.dart';
import '../models/category_model.dart';
import '../models/reminder_model.dart';

class DatabaseHelper {
  // Singleton pattern - only one instance of database
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mindscribe.db');
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented version for TTS columns
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }
  
  // Upgrade database when version changes
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('📊 Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add soundName column to reminders table
      try {
        await db.execute('ALTER TABLE reminders ADD COLUMN soundName TEXT');
        print('✅ Added soundName column to reminders table');
      } catch (e) {
        print('⚠️ Column might already exist: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Add TTS columns to reminders table
      try {
        await db.execute('ALTER TABLE reminders ADD COLUMN ttsEnabled INTEGER DEFAULT 1');
        print('✅ Added ttsEnabled column to reminders table');
      } catch (e) {
        print('⚠️ ttsEnabled column might already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE reminders ADD COLUMN ttsTitle TEXT');
        print('✅ Added ttsTitle column to reminders table');
      } catch (e) {
        print('⚠️ ttsTitle column might already exist: $e');
      }
      
      try {
        await db.execute('ALTER TABLE reminders ADD COLUMN ttsBody TEXT');
        print('✅ Added ttsBody column to reminders table');
      } catch (e) {
        print('⚠️ ttsBody column might already exist: $e');
      }
    }
  }

  // Create database tables
  Future _createDB(Database db, int version) async {
    // Entries table
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        eventDate TEXT,
        eventEndDate TEXT,
        isAllDay INTEGER DEFAULT 0,
        categoryId INTEGER,
        tags TEXT,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        progress INTEGER DEFAULT 0,
        type TEXT DEFAULT 'diary',
        isRecurring INTEGER DEFAULT 0,
        recurrenceRule TEXT,
        location TEXT,
        isFavorite INTEGER DEFAULT 0,
        isPrivate INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entryId TEXT NOT NULL,
        reminderTime TEXT NOT NULL,
        isRecurring INTEGER DEFAULT 0,
        recurrenceRule TEXT,
        isActive INTEGER DEFAULT 1,
        soundName TEXT,
        ttsEnabled INTEGER DEFAULT 1,
        ttsTitle TEXT,
        ttsBody TEXT,
        FOREIGN KEY (entryId) REFERENCES entries (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    for (var category in DefaultCategories.defaults) {
      await db.insert('categories', category.toMap());
    }
  }

  // ==================== ENTRY OPERATIONS ====================

  // Create new entry
  Future<EntryModel> createEntry(EntryModel entry) async {
    final db = await database;
    await db.insert('entries', entry.toMap());
    return entry;
  }

  // Get all entries
  Future<List<EntryModel>> getAllEntries() async {
    final db = await database;
    final result = await db.query('entries', orderBy: 'createdAt DESC');
    return result.map((map) => EntryModel.fromMap(map)).toList();
  }

  // Get entry by ID
  Future<EntryModel?> getEntry(String id) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return EntryModel.fromMap(maps.first);
    }
    return null;
  }

  // Update entry
  Future<int> updateEntry(EntryModel entry) async {
    final db = await database;
    return db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete entry
  Future<int> deleteEntry(String id) async {
    final db = await database;
    return await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get entries by category
  Future<List<EntryModel>> getEntriesByCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => EntryModel.fromMap(map)).toList();
  }

  // Get entries by date range
  Future<List<EntryModel>> getEntriesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'eventDate >= ? AND eventDate <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'eventDate ASC',
    );
    return result.map((map) => EntryModel.fromMap(map)).toList();
  }

  // Get entries by type (diary, event, task)
  Future<List<EntryModel>> getEntriesByType(String type) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => EntryModel.fromMap(map)).toList();
  }

  // Get favorite entries
  Future<List<EntryModel>> getFavoriteEntries() async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => EntryModel.fromMap(map)).toList();
  }

  // Search entries
  Future<List<EntryModel>> searchEntries(String query) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => EntryModel.fromMap(map)).toList();
  }

  // ==================== CATEGORY OPERATIONS ====================

  // Create category
  Future<Category> createCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Update category
  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Delete category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== REMINDER OPERATIONS ====================

  // Create reminder
  Future<Reminder> createReminder(Reminder reminder) async {
    final db = await database;
    final reminderMap = reminder.toMap();
    print('💾 Inserting reminder into database:');
    print('   Map: $reminderMap');
    final id = await db.insert('reminders', reminderMap);
    print('   ✅ Reminder inserted with ID: $id');
    return reminder.copyWith(id: id);
  }

  // Get reminders for entry
  Future<List<Reminder>> getRemindersForEntry(String entryId) async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'entryId = ?',
      whereArgs: [entryId],
      orderBy: 'reminderTime ASC',
    );
    print('📖 Loading reminders for entry: $entryId');
    print('   Found ${result.length} reminder(s)');
    for (var map in result) {
      print('   Reminder: isRecurring=${map['isRecurring']}, rule=${map['recurrenceRule']}, sound=${map['soundName']}');
    }
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  // Get all active reminders
  Future<List<Reminder>> getAllActiveReminders() async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'reminderTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  // Update reminder
  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // Delete reminder
  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all reminders for entry
  Future<int> deleteRemindersForEntry(String entryId) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'entryId = ?',
      whereArgs: [entryId],
    );
  }

  // ==================== UTILITY OPERATIONS ====================

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalEntries = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM entries')
    ) ?? 0;
    
    final totalTasks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM entries WHERE type = ?', ['task'])
    ) ?? 0;
    
    final completedTasks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM entries WHERE type = ? AND status = ?', ['task', 'completed'])
    ) ?? 0;
    
    final totalEvents = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM entries WHERE type = ?', ['event'])
    ) ?? 0;

    return {
      'totalEntries': totalEntries,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'totalEvents': totalEvents,
    };
  }
}
