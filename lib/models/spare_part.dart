enum PartStatus {
  needToBuy,
  ordered,
  received,
  installed,
}

extension PartStatusExt on PartStatus {
  String get label {
    switch (this) {
      case PartStatus.needToBuy:
        return 'Нужно купить';
      case PartStatus.ordered:
        return 'Заказано';
      case PartStatus.received:
        return 'Получено';
      case PartStatus.installed:
        return 'Установлено';
    }
  }

  static PartStatus fromKey(String key) {
    return PartStatus.values.firstWhere(
      (e) => e.name == key,
      orElse: () => PartStatus.needToBuy,
    );
  }
}

class SparePart {
  final int? id;
  final String name;
  final String category;
  final String? oemNumber;
  final List<String> analogs;
  final String? bestAnalog;
  final String? manufacturer;
  final double? price;
  final String? shop;
  final String? shopUrl;
  final DateTime? purchaseDate;
  final DateTime? installDate;
  final String? comment;
  final String? photoPartPath;
  final String? photoBoxPath;
  final PartStatus status;

  SparePart({
    this.id,
    required this.name,
    required this.category,
    this.oemNumber,
    this.analogs = const [],
    this.bestAnalog,
    this.manufacturer,
    this.price,
    this.shop,
    this.shopUrl,
    this.purchaseDate,
    this.installDate,
    this.comment,
    this.photoPartPath,
    this.photoBoxPath,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'oem_number': oemNumber,
      'analogs': analogs.join('|'),
      'best_analog': bestAnalog,
      'manufacturer': manufacturer,
      'price': price,
      'shop': shop,
      'shop_url': shopUrl,
      'purchase_date': purchaseDate?.toIso8601String(),
      'install_date': installDate?.toIso8601String(),
      'comment': comment,
      'photo_part_path': photoPartPath,
      'photo_box_path': photoBoxPath,
      'status': status.name,
    };
  }

  factory SparePart.fromMap(Map<String, dynamic> map) {
    final analogsStr = map['analogs'] as String? ?? '';
    return SparePart(
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? 'Другое',
      oemNumber: map['oem_number'],
      analogs: analogsStr.isEmpty ? [] : analogsStr.split('|'),
      bestAnalog: map['best_analog'],
      manufacturer: map['manufacturer'],
      price: (map['price'] as num?)?.toDouble(),
      shop: map['shop'],
      shopUrl: map['shop_url'],
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'])
          : null,
      installDate: map['install_date'] != null
          ? DateTime.parse(map['install_date'])
          : null,
      comment: map['comment'],
      photoPartPath: map['photo_part_path'],
      photoBoxPath: map['photo_box_path'],
      status: PartStatusExt.fromKey(map['status'] ?? 'needToBuy'),
    );
  }

  SparePart copyWith({
    int? id,
    String? name,
    String? category,
    String? oemNumber,
    List<String>? analogs,
    String? bestAnalog,
    String? manufacturer,
    double? price,
    String? shop,
    String? shopUrl,
    DateTime? purchaseDate,
    DateTime? installDate,
    String? comment,
    String? photoPartPath,
    String? photoBoxPath,
    PartStatus? status,
  }) {
    return SparePart(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      oemNumber: oemNumber ?? this.oemNumber,
      analogs: analogs ?? this.analogs,
      bestAnalog: bestAnalog ?? this.bestAnalog,
      manufacturer: manufacturer ?? this.manufacturer,
      price: price ?? this.price,
      shop: shop ?? this.shop,
      shopUrl: shopUrl ?? this.shopUrl,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      installDate: installDate ?? this.installDate,
      comment: comment ?? this.comment,
      photoPartPath: photoPartPath ?? this.photoPartPath,
      photoBoxPath: photoBoxPath ?? this.photoBoxPath,
      status: status ?? this.status,
    );
  }
}

const List<String> partCategories = [
  'Двигатель',
  'Фильтры',
  'Тормозная система',
  'Подвеска',
  'Рулевое управление',
  'Трансмиссия',
  'Электрика',
  'Кузов',
  'Салон',
  'Охлаждение',
  'Выхлопная система',
  'Топливная система',
  'Другое',
];
