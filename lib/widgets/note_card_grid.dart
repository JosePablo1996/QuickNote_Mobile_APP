// lib/widgets/note_card_grid.dart
// Tarjeta de nota en vista grid - VERSIÓN CON SOLO ICONOS
// ✅ Iconos grandes y visibles (24-28px)
// ✅ Sin textos en los botones
// ✅ Diseño responsivo que se adapta al tamaño de pantalla
// ✅ Botones: Editar, Eliminar, Favorito, Archivar (solo iconos)

import 'package:flutter/material.dart';
import 'package:quicknote/models/note.dart';

class NoteCardGrid extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleArchive;
  final bool isSelected;

  const NoteCardGrid({
    super.key,
    required this.note,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.onToggleArchive,
    this.isSelected = false,
  });

  Color get _noteColor => note.colorValue;
  Color get _backgroundColor => note.backgroundColor;
  IconConfig get _iconConfig => note.iconConfig;
  SizeConfig get _sizeConfig => note.sizeConfig;
  IntensityConfig get _intensityConfig => note.intensityConfig;
  ShapeConfig get _shapeConfig => note.shapeConfig;

  Widget _buildIcon(double size) {
    if (_iconConfig.value == NoteIcon.default_) {
      return Icon(Icons.edit_note, size: size, color: _noteColor);
    }
    return Text(_iconConfig.iconName, style: TextStyle(fontSize: size, color: _noteColor));
  }

  BorderRadius get _borderRadius => BorderRadius.circular(_shapeConfig.borderRadius);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected
              ? Border.all(color: theme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _intensityConfig.shadowIntensity * 0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y acciones
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              child: Row(
                children: [
                  // Icono de la nota
                  Container(
                    width: isSmallScreen ? 24 : 28,
                    height: isSmallScreen ? 24 : 28,
                    decoration: BoxDecoration(
                      color: _noteColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: _buildIcon(isSmallScreen ? 14 : 16)),
                  ),
                  const SizedBox(width: 6),
                  // Título
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _noteColor,
                        fontSize: _sizeConfig.value == NoteSize.compact ? (isSmallScreen ? 12 : 13) : (isSmallScreen ? 13 : 14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Indicadores de estado
                  if (note.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                  if (note.isArchived)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.archive, color: Colors.grey, size: 12),
                    ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10),
                child: Text(
                  note.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: _sizeConfig.value == NoteSize.compact ? (isSmallScreen ? 10 : 11) : (isSmallScreen ? 11 : 12),
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                  maxLines: _sizeConfig.contentLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Tags y fecha
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: note.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _noteColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(fontSize: isSmallScreen ? 7 : 8, color: _noteColor),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 6),
                  // Fila de fecha y acciones (iconos grandes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          note.relativeTime,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: isSmallScreen ? 8 : 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ✅ BARRA DE ACCIONES CON SOLO ICONOS (SIN TEXTOS)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón Editar
                          if (onEdit != null)
                            GestureDetector(
                              onTap: onEdit,
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.edit, size: isSmallScreen ? 18 : 20, color: Colors.blue),
                              ),
                            ),
                          const SizedBox(width: 4),
                          // Botón Archivar
                          if (onToggleArchive != null)
                            GestureDetector(
                              onTap: onToggleArchive,
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  note.isArchived ? Icons.unarchive : Icons.archive,
                                  size: isSmallScreen ? 18 : 20,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          // Botón Favorito
                          if (onToggleFavorite != null)
                            GestureDetector(
                              onTap: onToggleFavorite,
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: (note.isFavorite ? Colors.amber : Colors.grey).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  note.isFavorite ? Icons.star : Icons.star_border,
                                  size: isSmallScreen ? 18 : 20,
                                  color: note.isFavorite ? Colors.amber : Colors.grey,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          // Botón Eliminar
                          if (onDelete != null)
                            GestureDetector(
                              onTap: onDelete,
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.delete_outline, size: isSmallScreen ? 18 : 20, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}