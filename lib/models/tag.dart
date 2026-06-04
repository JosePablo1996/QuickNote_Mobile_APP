// lib/models/tag.dart
// Modelo de etiqueta

class Tag {
  final String name;
  final int? count;
  final String? color;
  final String? icon;
  final DateTime? createdAt;

  Tag({
    required this.name,
    this.count,
    this.color,
    this.icon,
    this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] ?? '',
      count: json['count'],
      color: json['color'],
      icon: json['icon'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (count != null) 'count': count,
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class TagStats {
  final String name;
  final int count;
  final String color;
  final String? icon;

  TagStats({
    required this.name,
    required this.count,
    required this.color,
    this.icon,
  });

  factory TagStats.fromJson(Map<String, dynamic> json) {
    return TagStats(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      color: json['color'] ?? '#3B82F6',
      icon: json['icon'],
    );
  }
}

class TagCloudItem {
  final String name;
  final int count;
  final double size;
  final String color;
  final String? icon;

  TagCloudItem({
    required this.name,
    required this.count,
    required this.size,
    required this.color,
    this.icon,
  });
}