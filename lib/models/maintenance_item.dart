class MaintenanceItem {
  final int? id;
  final String name;
  final String? brand;
  final DateTime? lastChangedDate;
  final int? lastChangedMileage;
  final int intervalKm;
  final int? intervalMonths;
  final double? cost;
  final String? comment;
  final String? photoPath;

  MaintenanceItem({
    this.id,
    required this.name,
    this.brand,
    this.lastChangedDate,
    this.lastChangedMileage,
    required this.intervalKm,
    this.intervalMonths,
    this.cost,
    this.comment,
    this.photoPath,
  });

  int? get nextChangeMileage {
    if (lastChangedMileage == null) return null;
    return lastChangedMileage! + intervalKm;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'last_changed_date': lastChangedDate?.toIso8601String(),
      'last_changed_mileage': lastChangedMileage,
      'interval_km': intervalKm,
      'interval_months': intervalMonths,
      'cost': cost,
      'comment': comment,
      'photo_path': photoPath,
    };
  }

  factory MaintenanceItem.fromMap(Map<String, dynamic> map) {
    return MaintenanceItem(
      id: map['id'],
      name: map['name'] ?? '',
      brand: map['brand'],
      lastChangedDate: map['last_changed_date'] != null
          ? DateTime.parse(map['last_changed_date'])
          : null,
      lastChangedMileage: map['last_changed_mileage'],
      intervalKm: map['interval_km'] ?? 10000,
      intervalMonths: map['interval_months'],
      cost: (map['cost'] as num?)?.toDouble(),
      comment: map['comment'],
      photoPath: map['photo_path'],
    );
  }

  MaintenanceItem copyWith({
    int? id,
    String? name,
    String? brand,
    DateTime? lastChangedDate,
    int? lastChangedMileage,
    int? intervalKm,
    int? intervalMonths,
    double? cost,
    String? comment,
    String? photoPath,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      lastChangedDate: lastChangedDate ?? this.lastChangedDate,
      lastChangedMileage: lastChangedMileage ?? this.lastChangedMileage,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      cost: cost ?? this.cost,
      comment: comment ?? this.comment,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
