// lib/core/utils/tag_utils.dart
// Utilidades para manejo de etiquetas (tags)

class TagUtils {
  // ============================================
  // COLORES PREDEFINIDOS PARA ETIQUETAS
  // ============================================
  static const Map<String, String> tagColors = {
    'personal': '#3B82F6',
    'trabajo': '#F59E0B',
    'estudio': '#10B981',
    'compras': '#8B5CF6',
    'ideas': '#EC4899',
    'proyecto': '#14B8A6',
    'urgente': '#EF4444',
    'salud': '#EC4899',
    'viajes': '#6366F1',
    'hogar': '#8B5CF6',
    'tecnología': '#3B82F6',
    'finanzas': '#10B981',
    'deportes': '#F59E0B',
    'música': '#8B5CF6',
    'lectura': '#6366F1',
  };

  static const List<String> defaultColors = [
    '#3B82F6', '#EF4444', '#10B981', '#F59E0B',
    '#8B5CF6', '#14B8A6', '#EC4899', '#6366F1',
  ];

  // ============================================
  // ICONOS PARA ETIQUETAS COMUNES
  // ============================================
  static const Map<String, String> tagIcons = {
    'personal': '👤',
    'trabajo': '💼',
    'estudio': '📚',
    'compras': '🛒',
    'ideas': '💡',
    'proyecto': '📊',
    'urgente': '⚠️',
    'salud': '❤️',
    'viajes': '✈️',
    'hogar': '🏠',
    'tecnología': '💻',
    'finanzas': '💰',
    'deportes': '⚽',
    'música': '🎵',
    'lectura': '📖',
  };

  // ============================================
  // OBTENER COLOR DE ETIQUETA
  // ============================================
  static String getTagColor(String tagName) {
    final lowerTag = tagName.toLowerCase();
    if (tagColors.containsKey(lowerTag)) {
      return tagColors[lowerTag]!;
    }
    
    // Generar color basado en hash
    final hash = _hashCode(lowerTag);
    return defaultColors[hash % defaultColors.length];
  }

  // ============================================
  // OBTENER COLOR DE FONDO CON OPACIDAD
  // ============================================
  static String getTagBackgroundColor(String tagName, {double opacity = 0.1}) {
    final color = getTagColor(tagName);
    final r = int.parse(color.substring(1, 3), radix: 16);
    final g = int.parse(color.substring(3, 5), radix: 16);
    final b = int.parse(color.substring(5, 7), radix: 16);
    return 'rgba($r, $g, $b, $opacity)';
  }

  // ============================================
  // OBTENER ICONO DE ETIQUETA
  // ============================================
  static String? getTagIcon(String tagName) {
    final lowerTag = tagName.toLowerCase();
    return tagIcons[lowerTag];
  }

  // ============================================
  // EXTRAER ETIQUETAS DEL CONTENIDO
  // ============================================
  static List<String> extractTagsFromContent(String content) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!.toLowerCase()).toList();
  }

  // ============================================
  // NORMALIZAR ETIQUETA
  // ============================================
  static String normalizeTag(String tag) {
    return tag.trim().toLowerCase();
  }

  // ============================================
  // VALIDAR ETIQUETA
  // ============================================
  static bool isValidTag(String tag) {
    final normalized = normalizeTag(tag);
    return normalized.isNotEmpty && 
           normalized.length <= 30 && 
           RegExp(r'^[a-zA-Z0-9áéíóúñüÁÉÍÓÚÑÜ\s]+$').hasMatch(normalized);
  }

  // ============================================
  // ELIMINAR DUPLICADOS
  // ============================================
  static List<String> removeDuplicates(List<String> tags) {
    return tags.toSet().toList();
  }

  // ============================================
  // ORDENAR ALFABÉTICAMENTE
  // ============================================
  static List<String> sortAlphabetically(List<String> tags) {
    final sorted = List<String>.from(tags);
    sorted.sort((a, b) => a.compareTo(b));
    return sorted;
  }

  // ============================================
  // FORMATO PARA MOSTRAR (#tag)
  // ============================================
  static String formatTagForDisplay(String tag) {
    return '#$tag';
  }

  // ============================================
  // FORMATEAR MÚLTIPLES ETIQUETAS
  // ============================================
  static String formatTagsForDisplay(List<String> tags, {int? limit}) {
    final displayTags = limit != null && tags.length > limit 
        ? tags.sublist(0, limit) 
        : tags;
    final formatted = displayTags.map((t) => '#$t').join(' ');
    
    if (limit != null && tags.length > limit) {
      return '$formatted +${tags.length - limit}';
    }
    return formatted;
  }

  // ============================================
  // ESTADÍSTICAS DE ETIQUETAS
  // ============================================
  static List<Map<String, dynamic>> getTagStats(List<List<String>> allTags) {
    final Map<String, int> counts = {};
    
    for (final tags in allTags) {
      for (final tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    
    return counts.entries.map((entry) => {
      'name': entry.key,
      'count': entry.value,
      'color': getTagColor(entry.key),
      'icon': getTagIcon(entry.key),
    }).toList()
    ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  // ============================================
  // DATOS PARA NUBE DE ETIQUETAS
  // ============================================
  static List<Map<String, dynamic>> getTagCloudData(
    List<List<String>> allTags, {
    int maxTags = 30,
  }) {
    final stats = getTagStats(allTags);
    if (stats.isEmpty) return [];
    
    final maxCount = stats.first['count'] as int;
    
    return stats.take(maxTags).map((stat) {
      final count = stat['count'] as int;
      final size = 12 + ((count / maxCount) * 12).round();
      return {
        ...stat,
        'size': size.clamp(12, 24),
      };
    }).toList();
  }

  // ============================================
  // SUGERIR ETIQUETAS BASADAS EN TEXTO
  // ============================================
  static List<String> suggestTags(String text, List<String> existingTags, {int limit = 5}) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final suggestions = <String>{};
    
    for (final word in words) {
      for (final tag in existingTags) {
        if (tag.contains(word) || word.contains(tag)) {
          suggestions.add(tag);
        }
      }
      
      if (word.length > 2 && !existingTags.contains(word) && isValidTag(word)) {
        suggestions.add(word);
      }
    }
    
    return suggestions.take(limit).toList();
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================
  static int _hashCode(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = (hash * 31 + str.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.abs();
  }
}