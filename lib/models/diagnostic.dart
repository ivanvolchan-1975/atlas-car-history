enum DiagnosticStatus {
  searching,
  waitingReplacement,
  inProgress,
  resolved,
}

extension DiagnosticStatusExt on DiagnosticStatus {
  String get label {
    switch (this) {
      case DiagnosticStatus.searching:
        return 'В поиске';
      case DiagnosticStatus.waitingReplacement:
        return 'Ожидает замены';
      case DiagnosticStatus.inProgress:
        return 'В работе';
      case DiagnosticStatus.resolved:
        return 'Устранено';
    }
  }

  String get key {
    return name;
  }

  static DiagnosticStatus fromKey(String key) {
    return DiagnosticStatus.values.firstWhere(
      (e) => e.name == key,
      orElse: () => DiagnosticStatus.searching,
    );
  }
}

class Diagnostic {
  final int? id;
  final String title;
  final String? description;
  final DiagnosticStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? cost;
  final List<String> photoPaths;

  Diagnostic({
    this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.cost,
    this.photoPaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'cost': cost,
      'photo_paths': photoPaths.join('|'),
    };
  }

  factory Diagnostic.fromMap(Map<String, dynamic> map) {
    final pathsStr = map['photo_paths'] as String? ?? '';
    return Diagnostic(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'],
      status: DiagnosticStatusExt.fromKey(map['status'] ?? 'searching'),
      createdAt: DateTime.parse(map['created_at']),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'])
          : null,
      cost: (map['cost'] as num?)?.toDouble(),
      photoPaths: pathsStr.isEmpty ? [] : pathsStr.split('|'),
    );
  }

  Diagnostic copyWith({
    int? id,
    String? title,
    String? description,
    DiagnosticStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    double? cost,
    List<String>? photoPaths,
  }) {
    return Diagnostic(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      cost: cost ?? this.cost,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }
}
