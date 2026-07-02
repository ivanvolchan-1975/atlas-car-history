enum DocumentType {
  insurance,
  techPassport,
  receipt,
  pdf,
  photo,
  other,
}

extension DocumentTypeExt on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.insurance:
        return 'Страховка';
      case DocumentType.techPassport:
        return 'Техпаспорт';
      case DocumentType.receipt:
        return 'Чек';
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.photo:
        return 'Фото';
      case DocumentType.other:
        return 'Другое';
    }
  }

  static DocumentType fromKey(String key) {
    return DocumentType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => DocumentType.other,
    );
  }
}

class Document {
  final int? id;
  final String title;
  final DocumentType type;
  final String filePath;
  final DateTime addedAt;
  final DateTime? expiresAt;
  final String? comment;

  Document({
    this.id,
    required this.title,
    required this.type,
    required this.filePath,
    required this.addedAt,
    this.expiresAt,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'file_path': filePath,
      'added_at': addedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'comment': comment,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'] ?? '',
      type: DocumentTypeExt.fromKey(map['type'] ?? 'other'),
      filePath: map['file_path'] ?? '',
      addedAt: DateTime.parse(map['added_at']),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : null,
      comment: map['comment'],
    );
  }

  Document copyWith({
    int? id,
    String? title,
    DocumentType? type,
    String? filePath,
    DateTime? addedAt,
    DateTime? expiresAt,
    String? comment,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      addedAt: addedAt ?? this.addedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      comment: comment ?? this.comment,
    );
  }
}
