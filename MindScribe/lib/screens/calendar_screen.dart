// Calendar Screen - View entries in calendar format

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import '../models/entry_model.dart';
import 'add_edit_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Consumer<EntryProvider>(
      builder: (context, entryProvider, child) {
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return entryProvider.getEntriesForDate(day);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: _buildEventsList(entryProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(EntryProvider entryProvider) {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Select a date to view entries'),
      );
    }

    final entries = entryProvider.getEntriesForDate(_selectedDay!);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No entries for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
              style: TextStyle(color: Colors.grey[600]),
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
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(EntryModel entry) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categoryColor = categoryProvider.getCategoryColor(entry.categoryId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor,
          child: Icon(
            _getTypeIcon(entry.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          entry.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          entry.eventDate != null && !entry.isAllDay
              ? DateFormat('HH:mm').format(entry.eventDate!)
              : 'All Day',
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditScreen(entry: entry, viewOnly: true),
            ),
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'task':
        return Icons.task_alt;
      case 'note':
        return Icons.lightbulb;
      default:
        return Icons.note;
    }
  }
}
