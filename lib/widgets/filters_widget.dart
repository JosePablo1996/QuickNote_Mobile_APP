// lib/widgets/filters_widget.dart
// Widget de filtros para notas - Independiente y reutilizable
// CON ANIMACIONES SUAVES Y SIN BOTTOM OVERFLOW

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';

// ============================================
// TIPOS DE FILTROS
// ============================================

enum SortOption {
  newest,
  oldest,
  titleAsc,
  titleDesc,
  favorites,
  updated,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.newest:
        return 'Más recientes';
      case SortOption.oldest:
        return 'Más antiguas';
      case SortOption.titleAsc:
        return 'Título (A-Z)';
      case SortOption.titleDesc:
        return 'Título (Z-A)';
      case SortOption.favorites:
        return 'Favoritas';
      case SortOption.updated:
        return 'Última actualización';
    }
  }

  String get shortName {
    switch (this) {
      case SortOption.newest:
        return 'Recientes';
      case SortOption.oldest:
        return 'Antiguas';
      case SortOption.titleAsc:
        return 'A-Z';
      case SortOption.titleDesc:
        return 'Z-A';
      case SortOption.favorites:
        return 'Favoritas';
      case SortOption.updated:
        return 'Actualizadas';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.newest:
        return Icons.arrow_downward;
      case SortOption.oldest:
        return Icons.arrow_upward;
      case SortOption.titleAsc:
        return Icons.sort_by_alpha;
      case SortOption.titleDesc:
        return Icons.sort_by_alpha;
      case SortOption.favorites:
        return Icons.star;
      case SortOption.updated:
        return Icons.update;
    }
  }
}

// ============================================
// CONFIGURACIÓN DE FILTROS
// ============================================

const List<Map<String, dynamic>> iconFilterOptions = [
  {'value': 'all', 'label': 'Todos', 'icon': Icons.grid_view},
  {'value': 'default', 'label': 'Default', 'icon': Icons.note},
  {'value': 'task', 'label': 'Tarea', 'icon': Icons.check_circle},
  {'value': 'important', 'label': 'Importante', 'icon': Icons.star},
  {'value': 'idea', 'label': 'Idea', 'icon': Icons.lightbulb},
  {'value': 'shopping', 'label': 'Compra', 'icon': Icons.shopping_cart},
  {'value': 'call', 'label': 'Llamada', 'icon': Icons.phone},
  {'value': 'email', 'label': 'Email', 'icon': Icons.email},
  {'value': 'travel', 'label': 'Viaje', 'icon': Icons.flight},
  {'value': 'health', 'label': 'Salud', 'icon': Icons.favorite},
  {'value': 'book', 'label': 'Libro', 'icon': Icons.book},
  {'value': 'code', 'label': 'Código', 'icon': Icons.code},
];

const List<Map<String, dynamic>> sizeFilterOptions = [
  {'value': 'all', 'label': 'Todos'},
  {'value': 'compact', 'label': 'Compacto'},
  {'value': 'normal', 'label': 'Normal'},
  {'value': 'expanded', 'label': 'Expandido'},
];

const List<Map<String, dynamic>> intensityFilterOptions = [
  {'value': 'all', 'label': 'Todos'},
  {'value': 'subtle', 'label': 'Sutil'},
  {'value': 'medium', 'label': 'Medio'},
  {'value': 'intense', 'label': 'Intenso'},
];

// ============================================
// WIDGET DE FILTROS CON ANIMACIÓN
// ============================================

class FiltersWidget extends StatefulWidget {
  final String selectedIcon;
  final String selectedSize;
  final String selectedIntensity;
  final SortOption sortBy;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<String> onIntensityChanged;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onClearAll;
  final bool showClearButton;
  final bool initiallyExpanded; // Nuevo: controlar si inicia expandido

  const FiltersWidget({
    super.key,
    required this.selectedIcon,
    required this.selectedSize,
    required this.selectedIntensity,
    required this.sortBy,
    required this.onIconChanged,
    required this.onSizeChanged,
    required this.onIntensityChanged,
    required this.onSortChanged,
    required this.onClearAll,
    this.showClearButton = true,
    this.initiallyExpanded = false, // Por defecto contraído
  });

  @override
  State<FiltersWidget> createState() => _FiltersWidgetState();
}

class _FiltersWidgetState extends State<FiltersWidget>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    
    // Controlador de animación para el ícono de rotación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.5, // 180 grados
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (_expanded) {
      _animationController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = widget.selectedIcon != 'all' ||
        widget.selectedSize != 'all' ||
        widget.selectedIntensity != 'all' ||
        widget.sortBy != SortOption.newest;

    return Column(
      mainAxisSize: MainAxisSize.min, // Importante: evitar overflow
      children: [
        // Botón principal para expandir/colapsar filtros
        _buildFilterHeader(isDarkMode, hasActiveFilters),
        
        // Panel expandible con animación suave
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _buildExpandedFiltersPanel(isDarkMode)
              : const SizedBox.shrink(),
        ),
        
        // Chips de filtros activos (versión compacta cuando está contraído)
        if (!_expanded && hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: _buildActiveFiltersRow(isDarkMode),
          ),
      ],
    );
  }

  // ============================================
  // HEADER DEL FILTRO
  // ============================================
  
  Widget _buildFilterHeader(bool isDarkMode, bool hasActiveFilters) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveFilters
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                : (isDarkMode ? Colors.white24 : Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 20,
              color: hasActiveFilters
                  ? const Color(0xFF8B5CF6)
                  : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Filtros y orden',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (hasActiveFilters && widget.showClearButton)
              GestureDetector(
                onTap: widget.onClearAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Limpiar',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value * 3.14159,
                  child: child,
                );
              },
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // PANEL DE FILTROS EXPANDIDO
  // ============================================

  Widget _buildExpandedFiltersPanel(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila 1: Icono
          _buildFilterOption(
            title: 'Icono',
            label: _getIconLabel(widget.selectedIcon),
            icon: Icons.emoji_emotions,
            onTap: () => _showIconFilterSheet(isDarkMode),
            isActive: widget.selectedIcon != 'all',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          
          // Fila 2: Tamaño
          _buildFilterOption(
            title: 'Tamaño',
            label: _getSizeLabel(widget.selectedSize),
            icon: Icons.crop,
            onTap: () => _showSizeSheet(isDarkMode),
            isActive: widget.selectedSize != 'all',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          
          // Fila 3: Intensidad
          _buildFilterOption(
            title: 'Intensidad',
            label: _getIntensityLabel(widget.selectedIntensity),
            icon: Icons.opacity,
            onTap: () => _showIntensitySheet(isDarkMode),
            isActive: widget.selectedIntensity != 'all',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          
          // Fila 4: Orden
          _buildFilterOption(
            title: 'Ordenar por',
            label: widget.sortBy.displayName,
            icon: Icons.sort,
            onTap: () => _showSortSheet(isDarkMode),
            isActive: widget.sortBy != SortOption.newest,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  // ============================================
  // OPCIÓN DE FILTRO INDIVIDUAL
  // ============================================

  Widget _buildFilterOption({
    required String title,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FILTROS ACTIVOS (VERSIÓN COMPACTA)
  // ============================================

  Widget _buildActiveFiltersRow(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (widget.selectedIcon != 'all')
            _buildActiveChip(
              label: _getIconLabel(widget.selectedIcon),
              onRemove: () => widget.onIconChanged('all'),
            ),
          if (widget.selectedSize != 'all')
            _buildActiveChip(
              label: _getSizeLabel(widget.selectedSize),
              onRemove: () => widget.onSizeChanged('all'),
            ),
          if (widget.selectedIntensity != 'all')
            _buildActiveChip(
              label: _getIntensityLabel(widget.selectedIntensity),
              onRemove: () => widget.onIntensityChanged('all'),
            ),
          if (widget.sortBy != SortOption.newest)
            _buildActiveChip(
              label: widget.sortBy.displayName,
              onRemove: () => widget.onSortChanged(SortOption.newest),
            ),
          GestureDetector(
            onTap: widget.onClearAll,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  'Limpiar todo',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: const Color(0xFF8B5CF6)),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BOTTOM SHEETS
  // ============================================

  void _showIconFilterSheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite scroll si hay muchos elementos
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filtrar por icono',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: iconFilterOptions.length,
                itemBuilder: (context, index) {
                  final option = iconFilterOptions[index];
                  final isSelected = widget.selectedIcon == option['value'];
                  return ListTile(
                    leading: Icon(option['icon'] as IconData, color: const Color(0xFF8B5CF6)),
                    title: Text(
                      option['label'] as String,
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: const Color(0xFF8B5CF6))
                        : null,
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    onTap: () {
                      widget.onIconChanged(option['value'] as String);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSizeSheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filtrar por tamaño',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            ...sizeFilterOptions.map((option) {
              final isSelected = widget.selectedSize == option['value'];
              return ListTile(
                title: Text(
                  option['label'] as String,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: const Color(0xFF8B5CF6))
                    : null,
                selected: isSelected,
                selectedTileColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                onTap: () {
                  widget.onSizeChanged(option['value'] as String);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showIntensitySheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filtrar por intensidad',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            ...intensityFilterOptions.map((option) {
              final isSelected = widget.selectedIntensity == option['value'];
              return ListTile(
                title: Text(
                  option['label'] as String,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: const Color(0xFF8B5CF6))
                    : null,
                selected: isSelected,
                selectedTileColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                onTap: () {
                  widget.onIntensityChanged(option['value'] as String);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ordenar por',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            ...SortOption.values.map((option) {
              final isSelected = widget.sortBy == option;
              return ListTile(
                leading: Icon(option.icon, color: const Color(0xFF8B5CF6)),
                title: Text(
                  option.displayName,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: const Color(0xFF8B5CF6))
                    : null,
                selected: isSelected,
                selectedTileColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                onTap: () {
                  widget.onSortChanged(option);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UTILIDADES
  // ============================================

  String _getIconLabel(String value) {
    if (value == 'all') return 'Todos';
    final icon = iconFilterOptions.firstWhere(
      (i) => i['value'] == value,
      orElse: () => iconFilterOptions.first,
    );
    return icon['label'] as String;
  }

  String _getSizeLabel(String value) {
    if (value == 'all') return 'Todos';
    final size = sizeFilterOptions.firstWhere(
      (s) => s['value'] == value,
      orElse: () => sizeFilterOptions.first,
    );
    return size['label'] as String;
  }

  String _getIntensityLabel(String value) {
    if (value == 'all') return 'Todos';
    final intensity = intensityFilterOptions.firstWhere(
      (i) => i['value'] == value,
      orElse: () => intensityFilterOptions.first,
    );
    return intensity['label'] as String;
  }
}