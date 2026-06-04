// lib/widgets/note_card_list.dart
// Tarjeta de nota en vista lista - VERSIÓN CON SOLO ICONOS
// ✅ Iconos grandes y visibles (22-24px)
// ✅ Sin textos en los botones
// ✅ Diseño responsivo que se adapta al tamaño de pantalla
// ✅ Botones: Editar, Eliminar, Favorito, Archivar (solo iconos)

import 'package:flutter/material.dart';
import 'package:quicknote/models/note.dart';

class NoteCardList extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleArchive;
  final bool isSelected;

  const NoteCardList({
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
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: 4),
        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected
              ? Border.all(color: theme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _intensityConfig.shadowIntensity * 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicador de color (barra lateral)
            Container(
              width: 3,
              height: isSmallScreen ? 35 : 40,
              decoration: BoxDecoration(
                color: _noteColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Icono de la nota
            Container(
              width: isSmallScreen ? 28 : 32,
              height: isSmallScreen ? 28 : 32,
              decoration: BoxDecoration(
                color: _noteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: _buildIcon(isSmallScreen ? 16 : 18)),
            ),
            const SizedBox(width: 10),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila del título
                  Row(
                    children: [
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
                      if (note.isFavorite)
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                      if (note.isArchived)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(Icons.archive, color: Colors.grey, size: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Contenido
                  Text(
                    note.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: _sizeConfig.value == NoteSize.compact ? (isSmallScreen ? 9 : 10) : (isSmallScreen ? 10 : 11),
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                    maxLines: _sizeConfig.value == NoteSize.compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tags y fecha
                  Row(
                    children: [
                      if (note.tags.isNotEmpty)
                        Flexible(
                          child: Wrap(
                            spacing: 4,
                            children: note.tags.take(2).map((tag) {
                              return Text(
                                '#$tag',
                                style: TextStyle(fontSize: isSmallScreen ? 7 : 8, color: _noteColor),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          note.relativeTime,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: isSmallScreen ? 8 : 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ✅ BARRA DE ACCIONES CON SOLO ICONOS (SIN TEXTOS)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        size: isSmallScreen ? 20 : 22,
                        color: note.isFavorite ? Colors.amber : Colors.grey,
                      ),
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
                        size: isSmallScreen ? 20 : 22,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
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
                      child: Icon(Icons.edit, size: isSmallScreen ? 20 : 22, color: Colors.blue),
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
                      child: Icon(Icons.delete_outline, size: isSmallScreen ? 20 : 22, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}