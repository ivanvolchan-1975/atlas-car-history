class Reminder {
  final int? id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final int? dueMileage;
  final bool isCompleted;
  final bool isRepeating;

  Reminder({
    this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.dueMileage,
    this.isCompleted = false,
    this.isRepeating = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'due_mileage': dueMileage,
      'is_completed': isCompleted ? 1 : 0,
      'is_repeating': isRepeating ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'],
      dueDate: DateTime.parse(map['due_date']),
      dueMileage: map['due_mileage'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      isRepeating: (map['is_repeating'] ?? 0) == 1,
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? dueMileage,
    bool? isCompleted,
    bool? isRepeating,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueMileage: dueMileage ?? this.dueMileage,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeating: isRepeating ?? this.isRepeating,
    );
  }
}
