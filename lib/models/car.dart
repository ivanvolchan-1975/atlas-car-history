class Car {
  final int? id;
  final String make;
  final String model;
  final String altModel;
  final String country;
  final int year;
  final String vin;
  final String engine;
  final String transmission;
  final int mileage;
  final String? photoPath;
  final DateTime? nextServiceDate;
  final int? nextServiceMileage;
  final int? lastServiceMileage;
  final DateTime? lastServiceDate;

  Car({
    this.id,
    required this.make,
    required this.model,
    required this.altModel,
    required this.country,
    required this.year,
    required this.vin,
    required this.engine,
    required this.transmission,
    required this.mileage,
    this.photoPath,
    this.nextServiceDate,
    this.nextServiceMileage,
    this.lastServiceMileage,
    this.lastServiceDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'alt_model': altModel,
      'country': country,
      'year': year,
      'vin': vin,
      'engine': engine,
      'transmission': transmission,
      'mileage': mileage,
      'photo_path': photoPath,
      'next_service_date': nextServiceDate?.toIso8601String(),
      'next_service_mileage': nextServiceMileage,
      'last_service_mileage': lastServiceMileage,
      'last_service_date': lastServiceDate?.toIso8601String(),
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      altModel: map['alt_model'] ?? '',
      country: map['country'] ?? '',
      year: map['year'] ?? 0,
      vin: map['vin'] ?? '',
      engine: map['engine'] ?? '',
      transmission: map['transmission'] ?? '',
      mileage: map['mileage'] ?? 0,
      photoPath: map['photo_path'],
      nextServiceDate: map['next_service_date'] != null
          ? DateTime.parse(map['next_service_date'])
          : null,
      nextServiceMileage: map['next_service_mileage'],
      lastServiceMileage: map['last_service_mileage'],
      lastServiceDate: map['last_service_date'] != null
          ? DateTime.parse(map['last_service_date'])
          : null,
    );
  }

  Car copyWith({
    int? id,
    String? make,
    String? model,
    String? altModel,
    String? country,
    int? year,
    String? vin,
    String? engine,
    String? transmission,
    int? mileage,
    String? photoPath,
    DateTime? nextServiceDate,
    int? nextServiceMileage,
    int? lastServiceMileage,
    DateTime? lastServiceDate,
  }) {
    return Car(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      altModel: altModel ?? this.altModel,
      country: country ?? this.country,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      engine: engine ?? this.engine,
      transmission: transmission ?? this.transmission,
      mileage: mileage ?? this.mileage,
      photoPath: photoPath ?? this.photoPath,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
      lastServiceMileage: lastServiceMileage ?? this.lastServiceMileage,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
    );
  }
}
