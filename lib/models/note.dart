// lib/models/note.dart
// Modelo de nota - COMPLETO con todas las propiedades de personalización
// Compatible con la versión de React de QuickNote

import 'package:flutter/material.dart';

// ============================================
// ENUMERACIONES Y TIPOS
// ============================================

/// Formas disponibles para las notas
enum NoteShape {
  square,   // Cuadrado (bordes rectos)
  rounded,  // Esquinas redondeadas (por defecto)
  oval,     // Forma ovalada
  pill,     // Forma de píldora
}

/// Iconos disponibles para las notas
enum NoteIcon {
  default_,    // Predeterminado
  task,        // Tarea
  meeting,     // Reunión
  important,   // Importante
  idea,        // Idea
  shopping,    // Compra
  call,        // Llamada
  email,       // Email
  document,    // Documento
  travel,      // Viaje
  health,      // Salud
  book,        // Libro
  code,        // Código
}

/// Tamaños disponibles para las notas
enum NoteSize {
  compact,  // Compacto
  normal,   // Normal (por defecto)
  expanded, // Expandido
}

/// Intensidad de color disponible para las notas
enum ColorIntensity {
  subtle,  // Sutil (opacidad baja)
  medium,  // Medio (por defecto)
  intense, // Intenso (opacidad alta)
}

// ============================================
// CONFIGURACIONES DE PERSONALIZACIÓN
// ============================================

/// Configuración de un icono
class IconConfig {
  final NoteIcon value;
  final String label;
  final String iconName;
  final Color color;
  final String description;

  const IconConfig({
    required this.value,
    required this.label,
    required this.iconName,
    required this.color,
    required this.description,
  });
}

/// Todos los iconos disponibles
const List<IconConfig> noteIcons = [
  IconConfig(
    value: NoteIcon.default_,
    label: 'Predeterminado',
    iconName: '📄',
    color: Color(0xFF6B7280),
    description: 'Nota estándar',
  ),
  IconConfig(
    value: NoteIcon.task,
    label: 'Tarea',
    iconName: '✅',
    color: Color(0xFFEF4444),
    description: 'Pendientes por completar',
  ),
  IconConfig(
    value: NoteIcon.meeting,
    label: 'Reunión',
    iconName: '👥',
    color: Color(0xFF8B5CF6),
    description: 'Notas de reuniones',
  ),
  IconConfig(
    value: NoteIcon.important,
    label: 'Importante',
    iconName: '⭐',
    color: Color(0xFFF59E0B),
    description: 'Información crítica',
  ),
  IconConfig(
    value: NoteIcon.idea,
    label: 'Idea',
    iconName: '💡',
    color: Color(0xFF10B981),
    description: 'Inspiración y creatividad',
  ),
  IconConfig(
    value: NoteIcon.shopping,
    label: 'Compra',
    iconName: '🛒',
    color: Color(0xFFEC4899),
    description: 'Listas de compras',
  ),
  IconConfig(
    value: NoteIcon.call,
    label: 'Llamada',
    iconName: '📞',
    color: Color(0xFF06B6D4),
    description: 'Llamadas pendientes',
  ),
  IconConfig(
    value: NoteIcon.email,
    label: 'Email',
    iconName: '📧',
    color: Color(0xFF3B82F6),
    description: 'Correos importantes',
  ),
  IconConfig(
    value: NoteIcon.document,
    label: 'Documento',
    iconName: '📄',
    color: Color(0xFF6366F1),
    description: 'Documentación',
  ),
  IconConfig(
    value: NoteIcon.travel,
    label: 'Viaje',
    iconName: '✈️',
    color: Color(0xFF14B8A6),
    description: 'Planes de viaje',
  ),
  IconConfig(
    value: NoteIcon.health,
    label: 'Salud',
    iconName: '❤️',
    color: Color(0xFF84CC16),
    description: 'Salud y bienestar',
  ),
  IconConfig(
    value: NoteIcon.book,
    label: 'Libro',
    iconName: '📚',
    color: Color(0xFFA855F7),
    description: 'Lecturas y resúmenes',
  ),
  IconConfig(
    value: NoteIcon.code,
    label: 'Código',
    iconName: '</>',
    color: Color(0xFF1E293B),
    description: 'Notas de programación',
  ),
];

/// Configuración de un tamaño
class SizeConfig {
  final NoteSize value;
  final String label;
  final String description;
  final String minHeight;
  final String padding;
  final String titleSize;
  final int contentLines;

  const SizeConfig({
    required this.value,
    required this.label,
    required this.description,
    required this.minHeight,
    required this.padding,
    required this.titleSize,
    required this.contentLines,
  });
}

/// Todos los tamaños disponibles
const List<SizeConfig> noteSizes = [
  SizeConfig(
    value: NoteSize.compact,
    label: 'Compacto',
    description: 'Máxima densidad de información',
    minHeight: '100px',
    padding: 'p-3',
    titleSize: 'text-sm',
    contentLines: 2,
  ),
  SizeConfig(
    value: NoteSize.normal,
    label: 'Normal',
    description: 'Equilibrio entre información y espacio',
    minHeight: '160px',
    padding: 'p-4',
    titleSize: 'text-base',
    contentLines: 3,
  ),
  SizeConfig(
    value: NoteSize.expanded,
    label: 'Expandido',
    description: 'Más espacio para contenido',
    minHeight: '220px',
    padding: 'p-5',
    titleSize: 'text-lg',
    contentLines: 4,
  ),
];

/// Configuración de intensidad de color
class IntensityConfig {
  final ColorIntensity value;
  final String label;
  final double bgOpacity;
  final double borderOpacity;
  final double shadowIntensity;
  final String description;

  const IntensityConfig({
    required this.value,
    required this.label,
    required this.bgOpacity,
    required this.borderOpacity,
    required this.shadowIntensity,
    required this.description,
  });
}

/// Todas las intensidades disponibles
const List<IntensityConfig> colorIntensities = [
  IntensityConfig(
    value: ColorIntensity.subtle,
    label: 'Sutil',
    bgOpacity: 0.05,
    borderOpacity: 0.2,
    shadowIntensity: 0.1,
    description: 'Fondo muy suave',
  ),
  IntensityConfig(
    value: ColorIntensity.medium,
    label: 'Medio',
    bgOpacity: 0.12,
    borderOpacity: 0.4,
    shadowIntensity: 0.2,
    description: 'Equilibrio perfecto',
  ),
  IntensityConfig(
    value: ColorIntensity.intense,
    label: 'Intenso',
    bgOpacity: 0.2,
    borderOpacity: 0.6,
    shadowIntensity: 0.3,
    description: 'Color bien marcado',
  ),
];

/// Configuración de forma
class ShapeConfig {
  final NoteShape value;
  final String label;
  final String icon;
  final String className;
  final double borderRadius;

  const ShapeConfig({
    required this.value,
    required this.label,
    required this.icon,
    required this.className,
    required this.borderRadius,
  });
}

/// Todas las formas disponibles
const List<ShapeConfig> noteShapes = [
  ShapeConfig(
    value: NoteShape.square,
    label: 'Cuadrado',
    icon: '⬛',
    className: 'rounded-none',
    borderRadius: 0,
  ),
  ShapeConfig(
    value: NoteShape.rounded,
    label: 'Esquinas redondas',
    icon: '🟫',
    className: 'rounded-xl',
    borderRadius: 12,
  ),
  ShapeConfig(
    value: NoteShape.oval,
    label: 'Ovalado',
    icon: '🥚',
    className: 'rounded-full aspect-video',
    borderRadius: 24,
  ),
  ShapeConfig(
    value: NoteShape.pill,
    label: 'Píldora',
    icon: '💊',
    className: 'rounded-full',
    borderRadius: 100,
  ),
];

// ============================================
// FUNCIONES DE UTILIDAD
// ============================================

/// Obtener configuración de icono
IconConfig getIconConfig(NoteIcon? icon) {
  if (icon == null) return noteIcons[0];
  return noteIcons.firstWhere(
    (i) => i.value == icon,
    orElse: () => noteIcons[0],
  );
}

/// Obtener configuración de tamaño
SizeConfig getSizeConfig(NoteSize? size) {
  if (size == null) return noteSizes[1];
  return noteSizes.firstWhere(
    (s) => s.value == size,
    orElse: () => noteSizes[1],
  );
}

/// Obtener configuración de intensidad
IntensityConfig getIntensityConfig(ColorIntensity? intensity) {
  if (intensity == null) return colorIntensities[1];
  return colorIntensities.firstWhere(
    (i) => i.value == intensity,
    orElse: () => colorIntensities[1],
  );
}

/// Obtener configuración de forma
ShapeConfig getShapeConfig(NoteShape? shape) {
  if (shape == null) return noteShapes[1];
  return noteShapes.firstWhere(
    (s) => s.value == shape,
    orElse: () => noteShapes[1],
  );
}

/// Obtener color con opacidad
Color getColorWithOpacity(String hexColor, double opacity) {
  final color = _getColorFromHex(hexColor);
  return color.withValues(alpha: opacity);
}

/// Convertir hex string a Color
Color _getColorFromHex(String hexColor) {
  final buffer = StringBuffer();
  if (hexColor.length == 6 || hexColor.length == 7) {
    buffer.write('ff');
    buffer.write(hexColor.replaceFirst('#', ''));
  }
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Convertir Color a hex string
String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2)}';
}

/// Obtener color de texto contrastante (blanco o negro según fondo)
Color getContrastColor(String hexColor) {
  final color = _getColorFromHex(hexColor);
  final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
  return luminance > 0.5 ? Colors.black : Colors.white;
}

/// Colores predefinidos para notas
const List<Color> predefinedColors = [
  Color(0xFF3B82F6), // Azul
  Color(0xFFEF4444), // Rojo
  Color(0xFF10B981), // Verde
  Color(0xFFF59E0B), // Ámbar
  Color(0xFF8B5CF6), // Púrpura
  Color(0xFFEC4899), // Rosa
  Color(0xFF06B6D4), // Cian
  Color(0xFFF97316), // Naranja
  Color(0xFF6366F1), // Índigo
  Color(0xFF14B8A6), // Teal
  Color(0xFF84CC16), // Lima
  Color(0xFFA855F7), // Violeta
];

const List<String> predefinedColorHexStrings = [
  '#3B82F6', '#EF4444', '#10B981', '#F59E0B',
  '#8B5CF6', '#EC4899', '#06B6D4', '#F97316',
  '#6366F1', '#14B8A6', '#84CC16', '#A855F7',
];

// ============================================
// MODELO NOTE
// ============================================

class Note {
  final String id;
  final String title;
  final String content;
  final String color;
  final NoteShape shape;
  final NoteIcon? icon;
  final NoteSize? size;
  final ColorIntensity? colorIntensity;
  final bool isFavorite;
  final bool isArchived;
  final List<String> tags;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Note({
    required this.id,
    required this.title,
    this.content = '',
    this.color = '#3B82F6',
    this.shape = NoteShape.rounded,
    this.icon,
    this.size,
    this.colorIntensity,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags = const [],
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ============================================
  // FACTORY METHODS
  // ============================================

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      color: json['color'] ?? '#3B82F6',
      shape: _parseShape(json['shape']),
      icon: _parseIcon(json['icon']),
      size: _parseSize(json['size']),
      colorIntensity: _parseIntensity(json['color_intensity'] ?? json['colorIntensity']),
      isFavorite: json['is_favorite'] ?? false,
      isArchived: json['is_archived'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['user_id']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'color': color,
    'shape': _shapeToString(shape),
    if (icon != null) 'icon': _iconToString(icon!),
    if (size != null) 'size': _sizeToString(size!),
    if (colorIntensity != null) 'color_intensity': _intensityToString(colorIntensity!),
    'is_favorite': isFavorite,
    'is_archived': isArchived,
    'tags': tags,
    if (userId != null) 'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };

  // ============================================
  // COPY WITH
  // ============================================

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? color,
    NoteShape? shape,
    NoteIcon? icon,
    NoteSize? size,
    ColorIntensity? colorIntensity,
    bool? isFavorite,
    bool? isArchived,
    List<String>? tags,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      shape: shape ?? this.shape,
      icon: icon ?? this.icon,
      size: size ?? this.size,
      colorIntensity: colorIntensity ?? this.colorIntensity,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // ============================================
  // GETTERS ÚTILES
  // ============================================

  bool get isActive => deletedAt == null && !isArchived;
  bool get isDeleted => deletedAt != null;
  
  IconConfig get iconConfig => getIconConfig(icon);
  SizeConfig get sizeConfig => getSizeConfig(size);
  IntensityConfig get intensityConfig => getIntensityConfig(colorIntensity);
  ShapeConfig get shapeConfig => getShapeConfig(shape);
  
  String get formattedCreatedAt => _formatDate(createdAt);
  String get formattedUpdatedAt => _formatDate(updatedAt);
  String get relativeTime => _getRelativeTime(updatedAt);
  
  Color get colorValue => _getColorFromHex(color);
  Color get backgroundColor => getColorWithOpacity(color, intensityConfig.bgOpacity);
  Color get borderColor => getColorWithOpacity(color, intensityConfig.borderOpacity);
  Color get contrastTextColor => getContrastColor(color);

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} meses';
    return 'Hace ${(diff.inDays / 365).floor()} años';
  }

  // ============================================
  // PARSERS
  // ============================================

  static NoteShape _parseShape(dynamic value) {
    if (value == null) return NoteShape.rounded;
    switch (value.toString().toLowerCase()) {
      case 'square': return NoteShape.square;
      case 'oval': return NoteShape.oval;
      case 'pill': return NoteShape.pill;
      default: return NoteShape.rounded;
    }
  }

  static NoteIcon? _parseIcon(dynamic value) {
    if (value == null) return null;
    switch (value.toString().toLowerCase()) {
      case 'task': return NoteIcon.task;
      case 'meeting': return NoteIcon.meeting;
      case 'important': return NoteIcon.important;
      case 'idea': return NoteIcon.idea;
      case 'shopping': return NoteIcon.shopping;
      case 'call': return NoteIcon.call;
      case 'email': return NoteIcon.email;
      case 'document': return NoteIcon.document;
      case 'travel': return NoteIcon.travel;
      case 'health': return NoteIcon.health;
      case 'book': return NoteIcon.book;
      case 'code': return NoteIcon.code;
      default: return null;
    }
  }

  static NoteSize? _parseSize(dynamic value) {
    if (value == null) return null;
    switch (value.toString().toLowerCase()) {
      case 'compact': return NoteSize.compact;
      case 'expanded': return NoteSize.expanded;
      default: return NoteSize.normal;
    }
  }

  static ColorIntensity? _parseIntensity(dynamic value) {
    if (value == null) return null;
    switch (value.toString().toLowerCase()) {
      case 'subtle': return ColorIntensity.subtle;
      case 'intense': return ColorIntensity.intense;
      default: return ColorIntensity.medium;
    }
  }

  static String _shapeToString(NoteShape shape) {
    switch (shape) {
      case NoteShape.square: return 'square';
      case NoteShape.oval: return 'oval';
      case NoteShape.pill: return 'pill';
      default: return 'rounded';
    }
  }

  static String _iconToString(NoteIcon icon) {
    switch (icon) {
      case NoteIcon.default_: return 'default';
      case NoteIcon.task: return 'task';
      case NoteIcon.meeting: return 'meeting';
      case NoteIcon.important: return 'important';
      case NoteIcon.idea: return 'idea';
      case NoteIcon.shopping: return 'shopping';
      case NoteIcon.call: return 'call';
      case NoteIcon.email: return 'email';
      case NoteIcon.document: return 'document';
      case NoteIcon.travel: return 'travel';
      case NoteIcon.health: return 'health';
      case NoteIcon.book: return 'book';
      case NoteIcon.code: return 'code';
    }
  }

  static String _sizeToString(NoteSize size) {
    switch (size) {
      case NoteSize.compact: return 'compact';
      case NoteSize.expanded: return 'expanded';
      default: return 'normal';
    }
  }

  static String _intensityToString(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.subtle: return 'subtle';
      case ColorIntensity.intense: return 'intense';
      default: return 'medium';
    }
  }
}

// ============================================
// MODELOS AUXILIARES
// ============================================

class NoteCreate {
  final String title;
  final String content;
  final String color;
  final NoteShape shape;
  final NoteIcon? icon;
  final NoteSize? size;
  final ColorIntensity? colorIntensity;
  final bool isFavorite;
  final bool isArchived;
  final List<String> tags;
  final String? userId;

  NoteCreate({
    required this.title,
    this.content = '',
    this.color = '#3B82F6',
    this.shape = NoteShape.rounded,
    this.icon,
    this.size,
    this.colorIntensity,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags = const [],
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'color': color,
    'shape': _shapeToString(shape),
    if (icon != null) 'icon': _iconToString(icon!),
    if (size != null) 'size': _sizeToString(size!),
    if (colorIntensity != null) 'color_intensity': _intensityToString(colorIntensity!),
    'is_favorite': isFavorite,
    'is_archived': isArchived,
    'tags': tags,
    if (userId != null) 'user_id': userId,
  };

  String _shapeToString(NoteShape shape) {
    switch (shape) {
      case NoteShape.square: return 'square';
      case NoteShape.oval: return 'oval';
      case NoteShape.pill: return 'pill';
      default: return 'rounded';
    }
  }

  String _iconToString(NoteIcon icon) {
    switch (icon) {
      case NoteIcon.default_: return 'default';
      case NoteIcon.task: return 'task';
      case NoteIcon.meeting: return 'meeting';
      case NoteIcon.important: return 'important';
      case NoteIcon.idea: return 'idea';
      case NoteIcon.shopping: return 'shopping';
      case NoteIcon.call: return 'call';
      case NoteIcon.email: return 'email';
      case NoteIcon.document: return 'document';
      case NoteIcon.travel: return 'travel';
      case NoteIcon.health: return 'health';
      case NoteIcon.book: return 'book';
      case NoteIcon.code: return 'code';
    }
  }

  String _sizeToString(NoteSize size) {
    switch (size) {
      case NoteSize.compact: return 'compact';
      case NoteSize.expanded: return 'expanded';
      default: return 'normal';
    }
  }

  String _intensityToString(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.subtle: return 'subtle';
      case ColorIntensity.intense: return 'intense';
      default: return 'medium';
    }
  }
}

class NoteUpdate {
  final String? title;
  final String? content;
  final String? color;
  final NoteShape? shape;
  final NoteIcon? icon;
  final NoteSize? size;
  final ColorIntensity? colorIntensity;
  final bool? isFavorite;
  final bool? isArchived;
  final List<String>? tags;
  final DateTime? deletedAt;

  NoteUpdate({
    this.title,
    this.content,
    this.color,
    this.shape,
    this.icon,
    this.size,
    this.colorIntensity,
    this.isFavorite,
    this.isArchived,
    this.tags,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (content != null) 'content': content,
    if (color != null) 'color': color,
    if (shape != null) 'shape': _shapeToString(shape!),
    if (icon != null) 'icon': _iconToString(icon!),
    if (size != null) 'size': _sizeToString(size!),
    if (colorIntensity != null) 'color_intensity': _intensityToString(colorIntensity!),
    if (isFavorite != null) 'is_favorite': isFavorite,
    if (isArchived != null) 'is_archived': isArchived,
    if (tags != null) 'tags': tags,
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };

  String _shapeToString(NoteShape shape) {
    switch (shape) {
      case NoteShape.square: return 'square';
      case NoteShape.oval: return 'oval';
      case NoteShape.pill: return 'pill';
      default: return 'rounded';
    }
  }

  String _iconToString(NoteIcon icon) {
    switch (icon) {
      case NoteIcon.default_: return 'default';
      case NoteIcon.task: return 'task';
      case NoteIcon.meeting: return 'meeting';
      case NoteIcon.important: return 'important';
      case NoteIcon.idea: return 'idea';
      case NoteIcon.shopping: return 'shopping';
      case NoteIcon.call: return 'call';
      case NoteIcon.email: return 'email';
      case NoteIcon.document: return 'document';
      case NoteIcon.travel: return 'travel';
      case NoteIcon.health: return 'health';
      case NoteIcon.book: return 'book';
      case NoteIcon.code: return 'code';
    }
  }

  String _sizeToString(NoteSize size) {
    switch (size) {
      case NoteSize.compact: return 'compact';
      case NoteSize.expanded: return 'expanded';
      default: return 'normal';
    }
  }

  String _intensityToString(ColorIntensity intensity) {
    switch (intensity) {
      case ColorIntensity.subtle: return 'subtle';
      case ColorIntensity.intense: return 'intense';
      default: return 'medium';
    }
  }
}