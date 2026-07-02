class ServiceRecord {
  final int? id;
  final DateTime date;
  final int mileage;
  final String description;
  final double cost;
  final String? comment;
  final List<String> photoPaths;

  ServiceRecord({
    this.id,
    required this.date,
    required this.mileage,
    required this.description,
    required this.cost,
    this.comment,
    this.photoPaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'description': description,
      'cost': cost,
      'comment': comment,
      'photo_paths': photoPaths.join('|'),
    };
  }

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    final pathsStr = map['photo_paths'] as String? ?? '';
    return ServiceRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mileage: map['mileage'] ?? 0,
      description: map['description'] ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'],
      photoPaths: pathsStr.isEmpty ? [] : pathsStr.split('|'),
    );
  }

  ServiceRecord copyWith({
    int? id,
    DateTime? date,
    int? mileage,
    String? description,
    double? cost,
    String? comment,
    List<String>? photoPaths,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      comment: comment ?? this.comment,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }
}
