// lib/widgets/tag_cloud.dart
// Nube de etiquetas - CON DISEÑO COMPLETO
// Similar a la versión de React de QuickNote

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/widgets/tag_chip.dart';

// ============================================
// UTILIDADES DE TAGS (integradas)
// ============================================

class _TagUtils {
  static const Map<String, String> _tagColors = {
    'trabajo': '#3B82F6',
    'personal': '#8B5CF6',
    'importante': '#EF4444',
    'idea': '#F59E0B',
    'proyecto': '#10B981',
    'estudio': '#EC4899',
    'casa': '#06B6D4',
    'compras': '#F97316',
    'salud': '#84CC16',
    'viaje': '#14B8A6',
  };

  static const Map<String, String> _tagIcons = {
    'trabajo': '💼',
    'personal': '👤',
    'importante': '⚠️',
    'idea': '💡',
    'proyecto': '📊',
    'estudio': '📚',
    'casa': '🏠',
    'compras': '🛒',
    'salud': '❤️',
    'viaje': '✈️',
  };

  static String getTagColor(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    return _tagColors[normalizedTag] ?? '#8B5CF6';
  }

  static String? getTagIcon(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    return _tagIcons[normalizedTag];
  }
}

// ============================================
// MODELO DE DATOS
// ============================================

class TagCloudItem {
  final String name;
  final int count;
  final double size;
  final Color color;
  final String? icon;
  final bool isSelected;

  const TagCloudItem({
    required this.name,
    required this.count,
    required this.size,
    required this.color,
    this.icon,
    this.isSelected = false,
  });
}

// ============================================
// WIDGET DE NUBE DE ETIQUETAS
// ============================================

class TagCloud extends StatelessWidget {
  final List<String> tags;
  final Map<String, int>? tagCounts;
  final Function(String)? onTagTap;
  final Function(String)? onTagDelete;
  final String? selectedTag;
  final int maxTags;
  final bool showCount;
  final bool showSearch;
  final bool showStats;
  final VoidCallback? onClearSelection;

  const TagCloud({
    super.key,
    required this.tags,
    this.tagCounts,
    this.onTagTap,
    this.onTagDelete,
    this.selectedTag,
    this.maxTags = 30,
    this.showCount = true,
    this.showSearch = false,
    this.showStats = true,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Procesar datos de la nube
    final cloudItems = _getTagCloudItems();
    final totalTags = tags.length;
    final totalUses = tagCounts?.values.reduce((a, b) => a + b) ?? 0;
    final hasSelection = selectedTag != null && selectedTag!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con estadísticas
        if (showStats)
          _buildStatsHeader(isDarkMode, totalTags, totalUses, hasSelection),
        
        // Barra de búsqueda (opcional)
        if (showSearch)
          _buildSearchBar(isDarkMode),
        
        // Etiqueta seleccionada (si existe)
        if (hasSelection && onClearSelection != null)
          _buildSelectedTagBar(isDarkMode),
        
        // Grid de etiquetas
        if (cloudItems.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          _buildTagGrid(isDarkMode, cloudItems),
        
        // Footer con resumen
        if (showStats && cloudItems.isNotEmpty)
          _buildFooter(isDarkMode, cloudItems.length, totalTags, totalUses),
      ],
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildStatsHeader(bool isDarkMode, int totalTags, int totalUses, bool hasSelection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Nube de Etiquetas',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          if (!hasSelection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalTags etiquetas',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    // Implementación básica - se puede expandir con búsqueda real
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18),
          const SizedBox(width: 8),
          Text(
            'Buscar etiquetas...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTagBar(bool isDarkMode) {
    final color = _getTagColor(selectedTag!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16),
          const SizedBox(width: 8),
          Text(
            'Filtrando por etiqueta:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          TagChipReadOnly(
            tag: selectedTag!,
            count: tagCounts?[selectedTag],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClearSelection,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close, size: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGrid(bool isDarkMode, List<TagCloudItem> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return AnimatedScale(
          scale: item.isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: () => onTagTap?.call(item.name),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: item.size * 0.6,
                vertical: item.size * 0.3,
              ),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: item.isSelected ? 0.25 : 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: item.color.withValues(alpha: item.isSelected ? 0.6 : 0.3),
                  width: item.isSelected ? 1.5 : 1,
                ),
                boxShadow: item.isSelected
                    ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        item.icon!,
                        style: TextStyle(fontSize: item.size * 0.8),
                      ),
                    ),
                  Text(
                    '#${item.name}',
                    style: GoogleFonts.poppins(
                      fontSize: item.size,
                      fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: item.color,
                    ),
                  ),
                  if (showCount && item.count > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCount(item.count),
                          style: GoogleFonts.poppins(
                            fontSize: item.size * 0.7,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                        ),
                      ),
                    ),
                  if (onTagDelete != null)
                    GestureDetector(
                      onTap: () => onTagDelete?.call(item.name),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.close,
                          size: item.size * 0.8,
                          color: item.color.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.label_off,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay etiquetas',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Las etiquetas aparecerán cuando las agregues a tus notas',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode, int displayedCount, int totalTags, int totalUses) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tag, size: 12, color: isDarkMode ? Colors.white38 : Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            '$displayedCount de $totalTags etiquetas',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$totalUses usos totales',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================

  List<TagCloudItem> _getTagCloudItems() {
    final items = <TagCloudItem>[];
    
    // Calcular estadísticas para tamaños
    final maxCount = tagCounts?.values.isNotEmpty == true
        ? tagCounts!.values.reduce((a, b) => a > b ? a : b)
        : 1;
    
    const minSize = 12.0;
    const maxSize = 28.0;
    
    // Limitar número de etiquetas
    final limitedTags = tags.take(maxTags).toList();
    
    for (final tag in limitedTags) {
      final count = tagCounts?[tag] ?? 1;
      final size = minSize + ((count / maxCount) * (maxSize - minSize));
      final color = _getTagColor(tag);
      final icon = _TagUtils.getTagIcon(tag);
      final isSelected = selectedTag == tag;
      
      items.add(TagCloudItem(
        name: tag,
        count: count,
        size: size.clamp(minSize, maxSize),
        color: color,
        icon: icon,
        isSelected: isSelected,
      ));
    }
    
    // Ordenar por frecuencia (mayor primero) para mejor visualización
    items.sort((a, b) => b.count.compareTo(a.count));
    
    return items;
  }

  Color _getTagColor(String tag) {
    final colorHex = _TagUtils.getTagColor(tag);
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return const Color(0xFF8B5CF6);
    }
  }

  String _formatCount(int count) {
    if (count > 99) return '99+';
    return '$count';
  }
}

// ============================================
// VARIANTES PREDEFINIDAS
// ============================================

/// Nube de etiquetas compacta (para espacios reducidos)
class TagCloudCompact extends StatelessWidget {
  final List<String> tags;
  final Map<String, int>? tagCounts;
  final Function(String)? onTagTap;
  final String? selectedTag;

  const TagCloudCompact({
    super.key,
    required this.tags,
    this.tagCounts,
    this.onTagTap,
    this.selectedTag,
  });

  @override
  Widget build(BuildContext context) {
    return TagCloud(
      tags: tags,
      tagCounts: tagCounts,
      onTagTap: onTagTap,
      selectedTag: selectedTag,
      maxTags: 15,
      showCount: false,
      showStats: false,
    );
  }
}

/// Nube de etiquetas expandida (con todas las características)
class TagCloudExpanded extends StatelessWidget {
  final List<String> tags;
  final Map<String, int>? tagCounts;
  final Function(String)? onTagTap;
  final Function(String)? onTagDelete;
  final String? selectedTag;
  final VoidCallback? onClearSelection;

  const TagCloudExpanded({
    super.key,
    required this.tags,
    this.tagCounts,
    this.onTagTap,
    this.onTagDelete,
    this.selectedTag,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return TagCloud(
      tags: tags,
      tagCounts: tagCounts,
      onTagTap: onTagTap,
      onTagDelete: onTagDelete,
      selectedTag: selectedTag,
      onClearSelection: onClearSelection,
      maxTags: 50,
      showCount: true,
      showSearch: true,
      showStats: true,
    );
  }
}

/// Nube de etiquetas interactiva (con animaciones)
class TagCloudInteractive extends StatelessWidget {
  final List<String> tags;
  final Map<String, int>? tagCounts;
  final Function(String)? onTagTap;
  final String? selectedTag;

  const TagCloudInteractive({
    super.key,
    required this.tags,
    this.tagCounts,
    this.onTagTap,
    this.selectedTag,
  });

  @override
  Widget build(BuildContext context) {
    return TagCloud(
      tags: tags,
      tagCounts: tagCounts,
      onTagTap: onTagTap,
      selectedTag: selectedTag,
      maxTags: 25,
      showCount: true,
      showStats: false,
    );
  }
}