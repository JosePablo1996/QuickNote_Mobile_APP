// lib/widgets/empty_state.dart
// Estado vacío para listas sin contenido - CON DISEÑO COMPLETO
// Similar a la versión de React de QuickNote

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// TIPO DE ESTADO VACÍO
// ============================================

enum EmptyStateType {
  notes,
  favorites,
  archived,
  trash,
  tags,
  search,
  backup,
  calendar,
  custom,
}

extension EmptyStateTypeExtension on EmptyStateType {
  String get title {
    switch (this) {
      case EmptyStateType.notes:
        return '¡Comienza a tomar notas!';
      case EmptyStateType.favorites:
        return 'No hay notas favoritas';
      case EmptyStateType.archived:
        return 'No hay notas archivadas';
      case EmptyStateType.trash:
        return 'La papelera está vacía';
      case EmptyStateType.tags:
        return 'No hay etiquetas';
      case EmptyStateType.search:
        return 'No se encontraron resultados';
      case EmptyStateType.backup:
        return 'No hay backups';
      case EmptyStateType.calendar:
        return 'No hay notas en este mes';
      case EmptyStateType.custom:
        return 'No hay elementos';
    }
  }

  String get message {
    switch (this) {
      case EmptyStateType.notes:
        return 'Tus ideas, pensamientos y recordatorios en un solo lugar';
      case EmptyStateType.favorites:
        return 'Las notas que marques como favoritas aparecerán aquí';
      case EmptyStateType.archived:
        return 'Las notas que archives aparecerán aquí';
      case EmptyStateType.trash:
        return 'Las notas que elimines aparecerán aquí';
      case EmptyStateType.tags:
        return 'Las etiquetas aparecerán cuando las agregues a tus notas';
      case EmptyStateType.search:
        return 'Intenta con otros términos de búsqueda';
      case EmptyStateType.backup:
        return 'Crea tu primer backup para proteger tus notas';
      case EmptyStateType.calendar:
        return 'Crea notas para verlas organizadas por fecha';
      case EmptyStateType.custom:
        return 'No hay elementos para mostrar';
    }
  }

  IconData get icon {
    switch (this) {
      case EmptyStateType.notes:
        return Icons.edit_note;
      case EmptyStateType.favorites:
        return Icons.star_border;
      case EmptyStateType.archived:
        return Icons.archive;
      case EmptyStateType.trash:
        return Icons.delete_outline;
      case EmptyStateType.tags:
        return Icons.tag;
      case EmptyStateType.search:
        return Icons.search_off;
      case EmptyStateType.backup:
        return Icons.cloud_off;
      case EmptyStateType.calendar:
        return Icons.calendar_today;
      case EmptyStateType.custom:
        return Icons.inbox;
    }
  }

  Color get iconColor {
    switch (this) {
      case EmptyStateType.notes:
        return Colors.blue;
      case EmptyStateType.favorites:
        return Colors.amber;
      case EmptyStateType.archived:
        return Colors.teal;
      case EmptyStateType.trash:
        return Colors.red;
      case EmptyStateType.tags:
        return Colors.purple;
      case EmptyStateType.search:
        return Colors.grey;
      case EmptyStateType.backup:
        return Colors.blue;
      case EmptyStateType.calendar:
        return Colors.green;
      case EmptyStateType.custom:
        return Colors.grey;
    }
  }

  String get defaultActionLabel {
    switch (this) {
      case EmptyStateType.notes:
        return 'Crear primera nota';
      case EmptyStateType.favorites:
        return 'Ir a todas las notas';
      case EmptyStateType.archived:
        return 'Ir a notas activas';
      case EmptyStateType.trash:
        return 'Ir a notas';
      case EmptyStateType.tags:
        return 'Ver todas las notas';
      case EmptyStateType.search:
        return 'Limpiar búsqueda';
      case EmptyStateType.backup:
        return 'Crear backup';
      case EmptyStateType.calendar:
        return 'Crear nota';
      case EmptyStateType.custom:
        return 'Agregar elemento';
    }
  }

  List<String> get tips {
    switch (this) {
      case EmptyStateType.notes:
        return ['Nueva nota', 'Organiza con etiquetas', 'Destaca favoritas'];
      case EmptyStateType.favorites:
        return ['Marca notas como favoritas ⭐', 'Usa el botón de estrella'];
      case EmptyStateType.archived:
        return ['Archiva notas desde el menú', 'Puedes restaurarlas después'];
      case EmptyStateType.trash:
        return ['Las notas se eliminan después de 30 días', 'Puedes restaurarlas'];
      case EmptyStateType.tags:
        return ['Agrega etiquetas al crear/editar notas', 'Usa # para crear etiquetas'];
      case EmptyStateType.backup:
        return ['Backups automáticos programados', 'Protege tus notas en la nube'];
      default:
        return [];
    }
  }
}

// ============================================
// WIDGET PRINCIPAL
// ============================================

class EmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateType type;
  final List<String>? customTips;
  final bool showTips;

  const EmptyState({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.type = EmptyStateType.custom,
    this.customTips,
    this.showTips = true,
  });

  // Fábricas para tipos predefinidos
  factory EmptyState.notes({VoidCallback? onCreate}) {
    return EmptyState(
      type: EmptyStateType.notes,
      onAction: onCreate,
    );
  }

  factory EmptyState.favorites({VoidCallback? onGoToNotes}) {
    return EmptyState(
      type: EmptyStateType.favorites,
      onAction: onGoToNotes,
    );
  }

  factory EmptyState.archived({VoidCallback? onGoToNotes}) {
    return EmptyState(
      type: EmptyStateType.archived,
      onAction: onGoToNotes,
    );
  }

  factory EmptyState.trash({VoidCallback? onGoToNotes}) {
    return EmptyState(
      type: EmptyStateType.trash,
      onAction: onGoToNotes,
    );
  }

  factory EmptyState.tags({VoidCallback? onGoToNotes}) {
    return EmptyState(
      type: EmptyStateType.tags,
      onAction: onGoToNotes,
    );
  }

  factory EmptyState.search(String query, {VoidCallback? onClear}) {
    return EmptyState(
      type: EmptyStateType.search,
      title: 'No se encontraron resultados',
      message: 'No se encontraron notas para "$query"',
      onAction: onClear,
      actionLabel: 'Limpiar búsqueda',
      showTips: false,
    );
  }

  factory EmptyState.backup({VoidCallback? onCreateBackup}) {
    return EmptyState(
      type: EmptyStateType.backup,
      onAction: onCreateBackup,
    );
  }

  factory EmptyState.calendar({VoidCallback? onCreateNote}) {
    return EmptyState(
      type: EmptyStateType.calendar,
      onAction: onCreateNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Obtener valores según el tipo
    final displayTitle = title ?? type.title;
    final displayMessage = message ?? type.message;
    final displayIcon = icon ?? type.icon;
    final displayIconColor = iconColor ?? type.iconColor;
    final displayActionLabel = actionLabel ?? type.defaultActionLabel;
    final tips = customTips ?? type.tips;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con efectos decorativos
            _buildAnimatedIcon(isDarkMode, displayIcon, displayIconColor),
            const SizedBox(height: 24),
            
            // Título
            _buildTitle(isDarkMode, displayTitle),
            const SizedBox(height: 8),
            
            // Mensaje
            _buildMessage(isDarkMode, displayMessage),
            const SizedBox(height: 24),
            
            // Botón de acción
            if (onAction != null)
              _buildActionButton(displayActionLabel, displayIconColor),
            
            // Tips adicionales
            if (showTips && tips.isNotEmpty)
              _buildTipsSection(isDarkMode, tips, displayIconColor),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildAnimatedIcon(bool isDarkMode, IconData icon, Color iconColor) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withValues(alpha: 0.2),
            iconColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo pulsante
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Container(
                width: 80 * value,
                height: 80 * value,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
              );
            },
          ),
          // Icono
          Icon(
            icon,
            size: 48,
            color: iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDarkMode, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(bool isDarkMode, String message) {
    return Text(
      message,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ✅ CORREGIDO: Se agregó el parámetro context y se eliminó la variable isDarkMode no usada
  Widget _buildActionButton(String label, Color iconColor) {
    return ElevatedButton.icon(
      onPressed: onAction,
      icon: Icon(_getActionIcon(), size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: iconColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildTipsSection(bool isDarkMode, List<String> tips, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                'Consejos útiles',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: iconColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    switch (type) {
      case EmptyStateType.notes:
        return Icons.add;
      case EmptyStateType.favorites:
        return Icons.arrow_forward;
      case EmptyStateType.archived:
        return Icons.arrow_forward;
      case EmptyStateType.trash:
        return Icons.arrow_forward;
      case EmptyStateType.tags:
        return Icons.arrow_forward;
      case EmptyStateType.search:
        return Icons.clear;
      case EmptyStateType.backup:
        return Icons.backup;
      case EmptyStateType.calendar:
        return Icons.add;
      default:
        return Icons.add;
    }
  }
}

// ============================================
// VARIANTES ADICIONALES
// ============================================

/// Estado vacío con animación de partículas
class EmptyStateAnimated extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateAnimated({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono animado con partículas
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Partículas alrededor del icono - CORREGIDO: angle ahora se usa
                      ...List.generate(8, (index) {
                        final radianAngle = index * 45 * (3.14159 / 180);
                        return Positioned(
                          left: 60 + 40 * value * (index % 2 == 0 ? 1 : -1),
                          top: 60 + 40 * value * (index % 3 == 0 ? 1 : -1),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                      Icon(icon, size: 56, color: color),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}