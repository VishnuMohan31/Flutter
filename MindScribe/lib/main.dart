import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MindScribeApp());
}

class MindScribeApp extends StatefulWidget {
  const MindScribeApp({super.key});

  @override
  State<MindScribeApp> createState() => _MindScribeAppState();
}

class _MindScribeAppState extends State<MindScribeApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _saveThemePreference();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindScribe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: DiaryHomePage(onThemeToggle: toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DiaryHomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  
  const DiaryHomePage({super.key, required this.onThemeToggle});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  List<DiaryEntry> diaryEntries = [];
  List<DiaryEntry> filteredEntries = [];
  bool isDarkMode = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  // Load diary entries from storage
  Future<void> _loadDiaryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('diary_entries') ?? [];
    
    setState(() {
      diaryEntries = entriesJson
          .map((entry) => DiaryEntry.fromJson(json.decode(entry)))
          .toList();
      filteredEntries = diaryEntries;
    });
  }

  // Save diary entries to storage
  Future<void> _saveDiaryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = diaryEntries
        .map((entry) => json.encode(entry.toJson()))
        .toList();
    await prefs.setStringList('diary_entries', entriesJson);
  }


  // Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Entries'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title or content...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
              _filterEntries();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
                filteredEntries = diaryEntries;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Filter entries based on search query
  void _filterEntries() {
    if (searchQuery.isEmpty) {
      filteredEntries = diaryEntries;
    } else {
      filteredEntries = diaryEntries.where((entry) {
        return entry.title.toLowerCase().contains(searchQuery) ||
               entry.content.toLowerCase().contains(searchQuery);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MindScribe',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onThemeToggle,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: diaryEntries.isEmpty
            ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 100,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Welcome to MindScribe!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Start writing your thoughts by tapping the + button',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEntries.isEmpty && searchQuery.isNotEmpty 
                    ? 1 
                    : filteredEntries.length,
                itemBuilder: (context, index) {
                  if (filteredEntries.isEmpty && searchQuery.isNotEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No entries found matching your search.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }
                  final entry = filteredEntries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        entry.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.date,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editEntry(index);
                          } else if (value == 'delete') {
                            _deleteEntry(index);
                          }
                        },
                      ),
                      onTap: () => _viewEntry(index),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntry,
        tooltip: 'Add New Entry',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEntryPage(
          onSave: (title, content) async {
            setState(() {
              diaryEntries.add(DiaryEntry(
                title: title,
                content: content,
                date: DateTime.now().toString().split(' ')[0],
              ));
              _filterEntries();
            });
            await _saveDiaryEntries();
          },
        ),
      ),
    );
  }

  void _editEntry(int index) {
    final entry = diaryEntries[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEntryPage(
          initialTitle: entry.title,
          initialContent: entry.content,
          onSave: (title, content) async {
            setState(() {
              diaryEntries[index] = DiaryEntry(
                title: title,
                content: content,
                date: entry.date,
              );
            });
            await _saveDiaryEntries();
          },
        ),
      ),
    );
  }

  void _viewEntry(int index) {
    final entry = diaryEntries[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewEntryPage(entry: entry),
      ),
    );
  }

  void _deleteEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                diaryEntries.removeAt(index);
              });
              await _saveDiaryEntries();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class DiaryEntry {
  final String title;
  final String content;
  final String date;

  DiaryEntry({
    required this.title,
    required this.content,
    required this.date,
  });

  // Convert DiaryEntry to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'date': date,
    };
  }

  // Create DiaryEntry from JSON
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      title: json['title'],
      content: json['content'],
      date: json['date'],
    );
  }
}

class AddEditEntryPage extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final Function(String title, String content) onSave;

  const AddEditEntryPage({
    super.key,
    this.initialTitle,
    this.initialContent,
    required this.onSave,
  });

  @override
  State<AddEditEntryPage> createState() => _AddEditEntryPageState();
}

class _AddEditEntryPageState extends State<AddEditEntryPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTitle == null ? 'New Entry' : 'Edit Entry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                widget.onSave(titleController.text, contentController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in both title and content'),
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'What\'s on your mind today?',
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Your thoughts...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewEntryPage extends StatelessWidget {
  final DiaryEntry entry;

  const ViewEntryPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Entry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.date,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  entry.content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
