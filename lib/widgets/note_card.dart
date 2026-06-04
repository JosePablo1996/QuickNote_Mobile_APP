// lib/widgets/note_card.dart
// Tarjeta base para mostrar notas - ACTUALIZADA
// Soporta iconos, formas, tamaños e intensidades de color

import 'package:flutter/material.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/widgets/note_card_grid.dart';
import 'package:quicknote/widgets/note_card_list.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleArchive;
  final bool isSelected;
  final bool isGridMode;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.onToggleArchive,
    this.isSelected = false,
    this.isGridMode = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridMode) {
      return NoteCardGrid(
        note: note,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleFavorite: onToggleFavorite,
        onToggleArchive: onToggleArchive,
        isSelected: isSelected,
      );
    } else {
      return NoteCardList(
        note: note,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleFavorite: onToggleFavorite,
        onToggleArchive: onToggleArchive,
        isSelected: isSelected,
      );
    }
  }
}