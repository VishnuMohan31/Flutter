// Add/Edit Screen - Create or edit entries with all features

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/entry_model.dart';
import '../models/reminder_model.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/voice_input_widget.dart';

class AddEditScreen extends StatefulWidget {
  final EntryModel? entry;
  final String? entryType;
  final bool viewOnly;

  const AddEditScreen({
    super.key,
    this.entry,
    this.entryType,
    this.viewOnly = false,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _locationController;

  late String _type;
  late String _priority;
  late String _status;
  int? _categoryId;
  DateTime? _eventDate;
  DateTime? _eventTime;
  bool _isAllDay = false;
  List<DateTime> _reminderTimes = [];
  bool _isFavorite = false;
  
  // Reminder settings
  String _recurrenceRule = 'none'; // none, daily, weekly, monthly
  String _notificationSound = 'default'; // default, or custom sound names

  @override
  void initState() {
    super.initState();

    if (widget.entry != null) {
      // Editing existing entry
      _titleController = TextEditingController(text: widget.entry!.title);
      _contentController = TextEditingController(text: widget.entry!.content);
      _locationController =
          TextEditingController(text: widget.entry!.location ?? '');
      _type = widget.entry!.type;
      _priority = widget.entry!.priority;
      _status = widget.entry!.status;
      _categoryId = widget.entry!.categoryId;
      _eventDate = widget.entry!.eventDate;
      _isAllDay = widget.entry!.isAllDay;
      _isFavorite = widget.entry!.isFavorite;

      // Load reminders
      _loadReminders();
    } else {
      // Creating new entry
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _locationController = TextEditingController();
      _type = widget.entryType ?? 'diary';
      _priority = 'medium';
      _status = 'pending';

      // Set default event date for events/tasks
      if (_type == 'event' || _type == 'task') {
        _eventDate = DateTime.now();
      }
    }
  }

  Future<void> _loadReminders() async {
    if (widget.entry != null) {
      final reminders = await Provider.of<EntryProvider>(context, listen: false)
          .getRemindersForEntry(widget.entry!.id);
      setState(() {
        _reminderTimes = reminders.map((r) => r.reminderTime).toList();
        // Load recurrence and sound from first reminder if exists
        if (reminders.isNotEmpty) {
          _recurrenceRule = reminders.first.recurrenceRule ?? 'none';
          _notificationSound = reminders.first.soundName ?? 'default';
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewOnly
            ? 'View Entry'
            : widget.entry == null
                ? 'New ${_type.capitalize()}'
                : 'Edit ${_type.capitalize()}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: widget.viewOnly
            ? null
            : [
                IconButton(
                  icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
                TextButton(
                  onPressed: _saveEntry,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with Voice Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                suffixIcon: widget.viewOnly
                    ? null
                    : VoiceInputWidget(
                        controller: _titleController,
                        fieldName: 'title',
                      ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              enabled: !widget.viewOnly,
            ),
            const SizedBox(height: 16),

            // Content with Voice Input
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                suffixIcon: widget.viewOnly
                    ? null
                    : VoiceInputWidget(
                        controller: _contentController,
                        fieldName: 'content',
                      ),
              ),
              maxLines: 8,
              enabled: !widget.viewOnly,
            ),
            const SizedBox(height: 16),

            // Category Selection
            if (!widget.viewOnly)
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // No Category option
                          ChoiceChip(
                            label: const Text('None', style: TextStyle(fontWeight: FontWeight.w500)),
                            selected: _categoryId == null,
                            backgroundColor: Colors.grey[200],
                            selectedColor: Colors.grey[400],
                            side: BorderSide(
                              color: _categoryId == null ? Colors.grey[600]! : Colors.grey[400]!,
                              width: _categoryId == null ? 2 : 1,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _categoryId = null;
                              });
                            },
                          ),
                          // Category options
                          ...categoryProvider.categories.map((category) {
                            final color = categoryProvider.getCategoryColor(category.id);
                            final isSelected = _categoryId == category.id;
                            return ChoiceChip(
                              label: Text(
                                category.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? color : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              backgroundColor: Colors.grey[200],
                              selectedColor: color.withOpacity(0.2),
                              side: BorderSide(
                                color: isSelected ? color : Colors.grey[400]!,
                                width: isSelected ? 2 : 1,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _categoryId = category.id;
                                });
                              },
                              avatar: isSelected
                                  ? Icon(Icons.check_circle, size: 18, color: color)
                                  : null,
                            );
                          }),
                        ],
                      ),
                    ],
                  );
                },
              ),
            if (!widget.viewOnly) const SizedBox(height: 20),

            // Priority Selection
            if (!widget.viewOnly)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPriorityChip('Low', 'low', Colors.green),
                      _buildPriorityChip('Medium', 'medium', Colors.blue),
                      _buildPriorityChip('High', 'high', Colors.orange),
                      _buildPriorityChip('Urgent', 'urgent', Colors.red),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Status (for tasks)
            if (_type == 'task')
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(
                      value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(
                      value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: widget.viewOnly
                    ? null
                    : (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
              ),
            if (_type == 'task') const SizedBox(height: 16),

            // Event Date (for events/tasks)
            if (_type == 'event' || _type == 'task')
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_eventDate == null
                    ? 'Set Date'
                    : DateFormat('MMM dd, yyyy').format(_eventDate!)),
                trailing: widget.viewOnly ? null : const Icon(Icons.edit),
                onTap: widget.viewOnly ? null : _pickDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            if (_type == 'event' || _type == 'task') const SizedBox(height: 16),

            // Event Time (for events)
            if (_type == 'event' && !_isAllDay)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_eventTime == null
                    ? 'Set Time'
                    : DateFormat('HH:mm').format(_eventTime!)),
                trailing: widget.viewOnly ? null : const Icon(Icons.edit),
                onTap: widget.viewOnly ? null : _pickTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            if (_type == 'event' && !_isAllDay) const SizedBox(height: 16),

            // All Day toggle (for events)
            if (_type == 'event')
              SwitchListTile(
                title: const Text('All Day Event'),
                value: _isAllDay,
                onChanged: widget.viewOnly
                    ? null
                    : (value) {
                        setState(() {
                          _isAllDay = value;
                        });
                      },
              ),
            if (_type == 'event') const SizedBox(height: 16),

            // Location (for events)
            if (_type == 'event')
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                enabled: !widget.viewOnly,
              ),
            if (_type == 'event') const SizedBox(height: 16),

            // Reminders
            if (!widget.viewOnly)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reminders',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addReminder,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  // Recurrence Selection
                  if (_reminderTimes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Repeat',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRecurrenceChip('None', 'none'),
                        _buildRecurrenceChip('Daily', 'daily'),
                        _buildRecurrenceChip('Weekly', 'weekly'),
                        _buildRecurrenceChip('Monthly', 'monthly'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Notification Sound Selection
                    const Text(
                      'Notification Sound',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _notificationSound,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.volume_up),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'default', child: Text('Default')),
                        DropdownMenuItem(value: 'gentle', child: Text('Gentle')),
                        DropdownMenuItem(value: 'alert', child: Text('Alert')),
                        DropdownMenuItem(value: 'chime', child: Text('Chime')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _notificationSound = value ?? 'default';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (_reminderTimes.isEmpty)
                    const Text('No reminders set',
                        style: TextStyle(color: Colors.grey)),
                  ..._reminderTimes.map((time) => ListTile(
                        leading: const Icon(Icons.notifications),
                        title:
                            Text(DateFormat('MMM dd, yyyy HH:mm').format(time)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _reminderTimes.remove(time);
                            });
                          },
                        ),
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _eventDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventTime ?? DateTime.now()),
    );
    if (time != null) {
      setState(() {
        _eventTime = DateTime(
          _eventDate?.year ?? DateTime.now().year,
          _eventDate?.month ?? DateTime.now().month,
          _eventDate?.day ?? DateTime.now().day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _addReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final reminderTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          _reminderTimes.add(reminderTime);
        });
      }
    }
  }

  void _saveEntry() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final entryProvider = Provider.of<EntryProvider>(context, listen: false);

    // Combine event date and time
    DateTime? finalEventDate;
    if (_eventDate != null) {
      if (_type == 'event' && !_isAllDay && _eventTime != null) {
        finalEventDate = DateTime(
          _eventDate!.year,
          _eventDate!.month,
          _eventDate!.day,
          _eventTime!.hour,
          _eventTime!.minute,
        );
      } else {
        finalEventDate = _eventDate;
      }
    }

    final entry = EntryModel(
      id: widget.entry?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      eventDate: finalEventDate,
      isAllDay: _isAllDay,
      categoryId: _categoryId,
      priority: _priority,
      status: _status,
      type: _type,
      location:
          _locationController.text.isEmpty ? null : _locationController.text,
      isFavorite: _isFavorite,
    );

    // Create reminders with recurrence and sound
    print('💾 Saving reminders with:');
    print('   Recurrence Rule: $_recurrenceRule');
    print('   Notification Sound: $_notificationSound');
    print('   Number of reminder times: ${_reminderTimes.length}');
    
    final reminders = _reminderTimes.map((time) {
      final reminder = Reminder(
        entryId: entry.id,
        reminderTime: time,
        isRecurring: _recurrenceRule != 'none',
        recurrenceRule: _recurrenceRule,
        soundName: _notificationSound != 'default' ? _notificationSound : null,
      );
      print('   Created reminder: isRecurring=${reminder.isRecurring}, rule=${reminder.recurrenceRule}, sound=${reminder.soundName}');
      return reminder;
    }).toList();

    if (widget.entry == null) {
      entryProvider.addEntry(entry, reminders);
    } else {
      entryProvider.updateEntry(entry, reminders);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Entry ${widget.entry == null ? 'created' : 'updated'}!')),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color) {
    final isSelected = _priority == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isSelected ? color : Colors.black87,
        ),
      ),
      selected: isSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: color.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[400]!,
        width: isSelected ? 2 : 1,
      ),
      onSelected: (selected) {
        setState(() {
          _priority = value;
        });
      },
      avatar: isSelected
          ? Icon(Icons.check_circle, size: 18, color: color)
          : null,
    );
  }
  
  Widget _buildRecurrenceChip(String label, String value) {
    final isSelected = _recurrenceRule == value;
    final color = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isSelected ? color : Colors.black87,
        ),
      ),
      selected: isSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: color.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[400]!,
        width: isSelected ? 2 : 1,
      ),
      onSelected: (selected) {
        setState(() {
          _recurrenceRule = value;
        });
      },
      avatar: isSelected
          ? Icon(Icons.check_circle, size: 18, color: color)
          : null,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
