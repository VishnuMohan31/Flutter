// Category Model - Represents a category like Work, Personal, Health, etc.

class Category {
  final int? id;              // Database ID (null for new categories)
  final String name;          // Category name (e.g., "Work")
  final String colorHex;      // Color in hex format (e.g., "#FF5733")
  final String icon;          // Icon name (e.g., "work", "home")

  Category({
    this.id,
    required this.name,
    required this.colorHex,
    required this.icon,
  });

  // Convert Category to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'icon': icon,
    };
  }

  // Create Category from Map (when reading from database)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      colorHex: map['colorHex'],
      icon: map['icon'],
    );
  }

  // Create a copy with some fields changed
  Category copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
    );
  }
}

// Default categories that will be created on first app launch
class DefaultCategories {
  static List<Category> get defaults => [
    Category(name: 'Personal', colorHex: '#2196F3', icon: 'person'),
    Category(name: 'Work', colorHex: '#FF9800', icon: 'work'),
    Category(name: 'Health', colorHex: '#4CAF50', icon: 'favorite'),
    Category(name: 'Finance', colorHex: '#9C27B0', icon: 'attach_money'),
    Category(name: 'Education', colorHex: '#00BCD4', icon: 'school'),
    Category(name: 'Travel', colorHex: '#FF5722', icon: 'flight'),
    Category(name: 'Goals', colorHex: '#FFC107', icon: 'flag'),
    Category(name: 'Ideas', colorHex: '#E91E63', icon: 'lightbulb'),
  ];
}
