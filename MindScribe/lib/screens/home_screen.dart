// Home Screen - Clean, Modern, User-Friendly UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../models/entry_model.dart';
import 'add_edit_screen.dart';
import 'calendar_screen.dart';
import '../widgets/entry_card.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MindScribe',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
          // Search
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
          // Filter
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildEntriesList() : const CalendarScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryOptions(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
    );
  }

  Widget _buildEntriesList() {
    return Consumer2<EntryProvider, CategoryProvider>(
      builder: (context, entryProvider, categoryProvider, child) {
        final entries = entryProvider.entries;

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_add_rounded,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Entries Yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the + button to create your first entry',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return EntryCard(
              entry: entry,
              onTap: () => _viewEntry(entry),
              onEdit: () => _editEntry(entry),
              onDelete: () => _deleteEntry(entry),
              onToggleFavorite: () => _toggleFavorite(entry),
              onMarkComplete: () => _markComplete(entry),
            );
          },
        );
      },
    );
  }

  void _showAddEntryOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create New Entry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(Icons.note_rounded, color: Colors.white),
              ),
              title: const Text('Diary Entry'),
              subtitle: const Text('Write your thoughts'),
              onTap: () {
                Navigator.pop(context);
                _addEntry('diary');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentOrange,
                child: Icon(Icons.event_rounded, color: Colors.white),
              ),
              title: const Text('Event'),
              subtitle: const Text('Schedule an event'),
              onTap: () {
                Navigator.pop(context);
                _addEntry('event');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentGreen,
                child: Icon(Icons.task_alt_rounded, color: Colors.white),
              ),
              title: const Text('Task'),
              subtitle: const Text('Create a to-do'),
              onTap: () {
                Navigator.pop(context);
                _addEntry('task');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentAmber,
                child: Icon(Icons.lightbulb_rounded, color: Colors.white),
              ),
              title: const Text('Quick Note'),
              subtitle: const Text('Jot down an idea'),
              onTap: () {
                Navigator.pop(context);
                _addEntry('note');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addEntry(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(entryType: type),
      ),
    );
  }

  void _editEntry(EntryModel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(entry: entry),
      ),
    );
  }

  void _viewEntry(EntryModel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(entry: entry, viewOnly: true),
      ),
    );
  }

  void _deleteEntry(EntryModel entry) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                await Provider.of<EntryProvider>(context, listen: false)
                    .deleteEntry(entry.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entry deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting entry: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(EntryModel entry) {
    Provider.of<EntryProvider>(context, listen: false).toggleFavorite(entry);
  }

  void _markComplete(EntryModel entry) {
    Provider.of<EntryProvider>(context, listen: false).markAsComplete(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task marked as complete!')),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search entries...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            Provider.of<EntryProvider>(context, listen: false)
                .searchEntries(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Provider.of<EntryProvider>(context, listen: false)
                  .searchEntries('');
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

  void _showFilterDialog() {
    final entryProvider = Provider.of<EntryProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Entries'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: entryProvider.selectedType == null,
                      onSelected: (_) {
                        entryProvider.filterByType(null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Diary'),
                      selected: entryProvider.selectedType == 'diary',
                      onSelected: (_) {
                        entryProvider.filterByType('diary');
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Event'),
                      selected: entryProvider.selectedType == 'event',
                      onSelected: (_) {
                        entryProvider.filterByType('event');
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Task'),
                      selected: entryProvider.selectedType == 'task',
                      onSelected: (_) {
                        entryProvider.filterByType('task');
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Note'),
                      selected: entryProvider.selectedType == 'note',
                      onSelected: (_) {
                        entryProvider.filterByType('note');
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: entryProvider.selectedCategoryId == null,
                      onSelected: (_) {
                        entryProvider.filterByCategory(null);
                        setState(() {});
                      },
                    ),
                    ...categoryProvider.categories.map((category) {
                      return FilterChip(
                        label: Text(category.name),
                        selected: entryProvider.selectedCategoryId == category.id,
                        onSelected: (_) {
                          entryProvider.filterByCategory(category.id);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                entryProvider.clearFilters();
                setState(() {});
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
