// Entry Model - Represents a diary entry or event/task

class EntryModel {
  final String id;            // Unique ID (UUID)
  final String title;         // Entry title
  final String content;       // Entry content/description
  final DateTime createdAt;   // When entry was created
  final DateTime? eventDate;  // For events: when the event happens
  final DateTime? eventEndDate; // For multi-day events
  final bool isAllDay;        // Is this an all-day event?
  
  // Organization
  final int? categoryId;      // Which category (Work, Personal, etc.)
  final List<String> tags;    // Tags for this entry
  
  // Task/Event features
  final String priority;      // 'low', 'medium', 'high', 'urgent'
  final String status;        // 'pending', 'in_progress', 'completed', 'cancelled'
  final int progress;         // 0-100 for tasks
  
  // Entry type
  final String type;          // 'diary', 'event', 'task', 'note'
  
  // Recurrence
  final bool isRecurring;     // Does this repeat?
  final String? recurrenceRule; // How it repeats
  
  // Additional info
  final String? location;     // Location for events
  final bool isFavorite;      // Starred/favorite
  final bool isPrivate;       // Private/confidential

  EntryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.eventDate,
    this.eventEndDate,
    this.isAllDay = false,
    this.categoryId,
    this.tags = const [],
    this.priority = 'medium',
    this.status = 'pending',
    this.progress = 0,
    this.type = 'diary',
    this.isRecurring = false,
    this.recurrenceRule,
    this.location,
    this.isFavorite = false,
    this.isPrivate = false,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'eventDate': eventDate?.toIso8601String(),
      'eventEndDate': eventEndDate?.toIso8601String(),
      'isAllDay': isAllDay ? 1 : 0,
      'categoryId': categoryId,
      'tags': tags.join(','), // Store tags as comma-separated string
      'priority': priority,
      'status': status,
      'progress': progress,
      'type': type,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceRule': recurrenceRule,
      'location': location,
      'isFavorite': isFavorite ? 1 : 0,
      'isPrivate': isPrivate ? 1 : 0,
    };
  }

  // Create from Map
  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      eventDate: map['eventDate'] != null ? DateTime.parse(map['eventDate']) : null,
      eventEndDate: map['eventEndDate'] != null ? DateTime.parse(map['eventEndDate']) : null,
      isAllDay: map['isAllDay'] == 1,
      categoryId: map['categoryId'],
      tags: map['tags'] != null && map['tags'].isNotEmpty 
          ? (map['tags'] as String).split(',') 
          : [],
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      progress: map['progress'] ?? 0,
      type: map['type'] ?? 'diary',
      isRecurring: map['isRecurring'] == 1,
      recurrenceRule: map['recurrenceRule'],
      location: map['location'],
      isFavorite: map['isFavorite'] == 1,
      isPrivate: map['isPrivate'] == 1,
    );
  }

  // Copy with changes
  EntryModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? eventDate,
    DateTime? eventEndDate,
    bool? isAllDay,
    int? categoryId,
    List<String>? tags,
    String? priority,
    String? status,
    int? progress,
    String? type,
    bool? isRecurring,
    String? recurrenceRule,
    String? location,
    bool? isFavorite,
    bool? isPrivate,
  }) {
    return EntryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      eventDate: eventDate ?? this.eventDate,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      isAllDay: isAllDay ?? this.isAllDay,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      location: location ?? this.location,
      isFavorite: isFavorite ?? this.isFavorite,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
