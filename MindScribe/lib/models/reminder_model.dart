// Reminder Model - Represents a reminder/notification for an entry

class Reminder {
  final int? id; // Database ID
  final String entryId; // Which entry this reminder belongs to
  final DateTime reminderTime; // When to show the reminder
  final bool isRecurring; // Does it repeat?
  final String? recurrenceRule; // How it repeats (daily, weekly, monthly, none)
  final bool isActive; // Is this reminder active?
  final String? soundName; // Custom notification sound
  
  // TTS fields
  final bool ttsEnabled; // Should notification speak?
  final String? ttsTitle; // Title to speak
  final String? ttsBody; // Content to speak

  Reminder({
    this.id,
    required this.entryId,
    required this.reminderTime,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isActive = true,
    this.soundName,
    this.ttsEnabled = true,
    this.ttsTitle,
    this.ttsBody,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryId': entryId,
      'reminderTime': reminderTime.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceRule': recurrenceRule,
      'isActive': isActive ? 1 : 0,
      'soundName': soundName,
      'ttsEnabled': ttsEnabled ? 1 : 0,
      'ttsTitle': ttsTitle,
      'ttsBody': ttsBody,
    };
  }

  // Create from Map
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      entryId: map['entryId'],
      reminderTime: DateTime.parse(map['reminderTime']),
      isRecurring: map['isRecurring'] == 1,
      recurrenceRule: map['recurrenceRule'],
      isActive: map['isActive'] == 1,
      soundName: map['soundName'],
    );
  }

  // Copy with changes
  Reminder copyWith({
    int? id,
    String? entryId,
    DateTime? reminderTime,
    bool? isRecurring,
    String? recurrenceRule,
    bool? isActive,
    String? soundName,
  }) {
    return Reminder(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      reminderTime: reminderTime ?? this.reminderTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isActive: isActive ?? this.isActive,
      soundName: soundName ?? this.soundName,
    );
  }
  
  // Calculate next occurrence for recurring reminders
  DateTime? getNextOccurrence() {
    if (!isRecurring || recurrenceRule == null || recurrenceRule == 'none') {
      return null;
    }
    
    final now = DateTime.now();
    DateTime next = reminderTime;
    
    // Keep calculating next occurrence until it's in the future
    while (next.isBefore(now)) {
      switch (recurrenceRule) {
        case 'daily':
          next = DateTime(next.year, next.month, next.day + 1, next.hour, next.minute);
          break;
        case 'weekly':
          next = DateTime(next.year, next.month, next.day + 7, next.hour, next.minute);
          break;
        case 'monthly':
          next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
          break;
        default:
          return null;
      }
    }
    
    return next;
  }
}
