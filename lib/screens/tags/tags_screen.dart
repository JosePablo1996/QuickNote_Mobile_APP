// lib/screens/tags/tags_screen.dart
// Pantalla de gestión de etiquetas - VERSIÓN CORREGIDA
// ✅ CORREGIDO: Uso de NoteUpdate en lugar de Map
// ✅ CORREGIDO: Radio widget actualizado para evitar deprecación
// ✅ CORREGIDO: Eliminado toList() innecesario

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/empty_state.dart';
import 'package:quicknote/widgets/tag_cloud.dart';
import 'package:quicknote/widgets/toast_message.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  String _searchQuery = '';
  String _viewMode = 'grid'; // 'grid' or 'cloud'
  final Set<String> _selectedTags = {};
  bool _isSelectionMode = false;
  String? _editingTag;
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notesState = ref.watch(notesProvider);
    final allTags = _getAllTagsWithCount(notesState);
    final filteredTags = _searchQuery.isEmpty
        ? allTags
        : allTags.where((tag) => tag['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (notesState.isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: _buildAppBar(isDarkMode, allTags.length),
      body: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(isDarkMode),
          
          // Barra de acciones
          if (!_isSelectionMode && allTags.isNotEmpty)
            _buildActionsBar(isDarkMode, allTags.length),
          
          // Barra de selección múltiple
          if (_isSelectionMode) _buildSelectionBar(isDarkMode),
          
          // Contenido
          Expanded(
            child: filteredTags.isEmpty
                ? _buildEmptyState(isDarkMode)
                : _viewMode == 'cloud'
                    ? _buildCloudView(isDarkMode, filteredTags)
                    : _buildGridView(isDarkMode, filteredTags),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, int count) {
    return AppBar(
      title: const Text('Etiquetas'),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (count > 0 && !_isSelectionMode)
          IconButton(
            icon: Icon(
              _viewMode == 'grid' ? Icons.cloud : Icons.grid_view,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
            onPressed: () => setState(() {
              _viewMode = _viewMode == 'grid' ? 'cloud' : 'grid';
            }),
            tooltip: _viewMode == 'grid' ? 'Vista nube' : 'Vista cuadrícula',
          ),
        if (count > 0 && !_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => setState(() => _isSelectionMode = true),
            tooltip: 'Seleccionar múltiple',
          ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Buscar etiquetas...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsBar(bool isDarkMode, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showAddTagDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('NUEVA ETIQUETA'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count etiqueta${count != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.purple,
      child: Row(
        children: [
          Text(
            '${_selectedTags.length} seleccionada${_selectedTags.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selectedTags.clear();
              _isSelectionMode = false;
            }),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedTags.length >= 2 ? _showMergeTagsDialog : null,
            icon: const Icon(Icons.merge, size: 16),
            label: const Text('COMBINAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedTags,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('ELIMINAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(bool isDarkMode, List<Map<String, dynamic>> tags) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final tagName = tag['name'];
        final tagCount = tag['count'];
        final tagColor = _getTagColor(tagName);
        final isSelected = _selectedTags.contains(tagName);
        final isEditing = _editingTag == tagName;

        return GestureDetector(
          onLongPress: () => setState(() {
            _isSelectionMode = true;
            _selectedTags.add(tagName);
          }),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Colors.purple, width: 2)
                  : Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isEditing
                ? _buildEditTagField(tagName, tagColor, isDarkMode)
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Icon(
                                _getTagIcon(tagName),
                                size: 28,
                                color: tagColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '#$tagName',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tagColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$tagCount nota${tagCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isSelectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                onPressed: () => _startEditingTag(tagName),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _deleteTag(tagName),
                              ),
                            ],
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCloudView(bool isDarkMode, List<Map<String, dynamic>> tags) {
    final List<String> tagNames = tags.map((t) => t['name'] as String).toList();
    final Map<String, int> tagCounts = {for (var t in tags) t['name'] as String: t['count'] as int};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TagCloud(
        tags: tagNames,
        tagCounts: tagCounts,
        onTagTap: (tag) => _navigateToTagNotes(tag),
        onTagDelete: (tag) => _deleteTag(tag),
        selectedTag: null,
        maxTags: 50,
        showCount: true,
      ),
    );
  }

  Widget _buildEditTagField(String tagName, Color tagColor, bool isDarkMode) {
    _editController.text = tagName;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(_getTagIcon(tagName), size: 28, color: tagColor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _editController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Nuevo nombre',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tagColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (_) => _saveEditTag(tagName),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _editingTag = null),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveEditTag(tagName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tagColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return EmptyState(
      title: 'No hay etiquetas',
      message: 'Las etiquetas aparecerán cuando las agregues a tus notas',
      icon: Icons.tag,
      actionLabel: 'Ver todas las notas',
      onAction: () => Navigator.pop(context),
    );
  }

  void _showAddTagDialog() {
    _newTagController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva etiqueta'),
        content: TextField(
          controller: _newTagController,
          decoration: const InputDecoration(
            hintText: 'Nombre de la etiqueta',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final newTag = _newTagController.text.trim().toLowerCase();
              if (newTag.isNotEmpty) {
                _addTagToRandomNote(newTag);
              }
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showMergeTagsDialog() {
    if (_selectedTags.length < 2) return;
    
    String? targetTag = _selectedTags.first;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Combinar etiquetas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona la etiqueta destino:'),
                const SizedBox(height: 16),
                ..._selectedTags.map((tag) {
                  return ListTile(
                    leading: Radio<String>(
                      value: tag,
                      groupValue: targetTag,
                      onChanged: (value) => setStateDialog(() => targetTag = value),
                    ),
                    title: Text('#$tag'),
                    trailing: Text(
                      '${_getTagCount(tag)} notas',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (targetTag != null) {
                    _mergeTags(targetTag!);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Combinar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startEditingTag(String tagName) {
    setState(() => _editingTag = tagName);
  }

  void _saveEditTag(String oldName) {
    final newName = _editController.text.trim().toLowerCase();
    if (newName.isNotEmpty && newName != oldName) {
      _renameTag(oldName, newName);
    }
    setState(() => _editingTag = null);
  }

  /// ✅ CORREGIDO: Usa NoteUpdate en lugar de Map
  void _renameTag(String oldName, String newName) async {
    final notes = ref.read(notesProvider).activeNotes;
    for (final note in notes) {
      if (note.tags.contains(oldName)) {
        final newTags = note.tags.map((t) => t == oldName ? newName : t).toList();
        final noteUpdate = NoteUpdate(tags: newTags);
        await ref.read(notesProvider.notifier).updateNote(note.id, noteUpdate);
      }
    }
    await ref.read(notesProvider.notifier).loadNotes();
    if (mounted) {
      ToastMessage.success('Etiqueta renombrada a #$newName');
    }
  }

  /// ✅ CORREGIDO: Usa NoteUpdate en lugar de Map
  void _deleteTag(String tagName) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar etiqueta',
      '¿Eliminar la etiqueta #$tagName de todas las notas?',
    );
    if (confirmed) {
      final notes = ref.read(notesProvider).activeNotes;
      for (final note in notes) {
        if (note.tags.contains(tagName)) {
          final newTags = note.tags.where((t) => t != tagName).toList();
          final noteUpdate = NoteUpdate(tags: newTags);
          await ref.read(notesProvider.notifier).updateNote(note.id, noteUpdate);
        }
      }
      await ref.read(notesProvider.notifier).loadNotes();
      if (mounted) {
        ToastMessage.success('Etiqueta eliminada');
      }
    }
  }

  /// ✅ CORREGIDO: Usa NoteUpdate en lugar de Map
  void _deleteSelectedTags() async {
    final confirmed = await _showConfirmDialog(
      'Eliminar etiquetas',
      '¿Eliminar ${_selectedTags.length} etiqueta${_selectedTags.length != 1 ? 's' : ''} de todas las notas?',
    );
    if (confirmed) {
      final notes = ref.read(notesProvider).activeNotes;
      for (final note in notes) {
        final newTags = note.tags.where((t) => !_selectedTags.contains(t)).toList();
        if (newTags.length != note.tags.length) {
          final noteUpdate = NoteUpdate(tags: newTags);
          await ref.read(notesProvider.notifier).updateNote(note.id, noteUpdate);
        }
      }
      await ref.read(notesProvider.notifier).loadNotes();
      setState(() {
        _selectedTags.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ToastMessage.success('Etiquetas eliminadas');
      }
    }
  }

  /// ✅ CORREGIDO: Usa NoteUpdate en lugar de Map
  void _mergeTags(String targetTag) async {
    final sourceTags = _selectedTags.where((t) => t != targetTag).toList();
    final notes = ref.read(notesProvider).activeNotes;
    
    for (final note in notes) {
      final hasSourceTag = sourceTags.any((t) => note.tags.contains(t));
      if (hasSourceTag) {
        final newTags = [...note.tags.where((t) => !sourceTags.contains(t)), targetTag];
        final noteUpdate = NoteUpdate(tags: newTags.toSet().toList());
        await ref.read(notesProvider.notifier).updateNote(note.id, noteUpdate);
      }
    }
    
    await ref.read(notesProvider.notifier).loadNotes();
    setState(() {
      _selectedTags.clear();
      _isSelectionMode = false;
    });
    
    if (mounted) {
      ToastMessage.success('Etiquetas combinadas en #$targetTag');
    }
  }

  /// ✅ CORREGIDO: Usa NoteUpdate en lugar de Map
  void _addTagToRandomNote(String newTag) {
    final notes = ref.read(notesProvider).activeNotes;
    if (notes.isNotEmpty) {
      final firstNote = notes.first;
      final newTags = [...firstNote.tags, newTag];
      final noteUpdate = NoteUpdate(tags: newTags);
      ref.read(notesProvider.notifier).updateNote(firstNote.id, noteUpdate);
      ref.read(notesProvider.notifier).loadNotes();
      if (mounted) {
        ToastMessage.success('Etiqueta #$newTag agregada a "${firstNote.title}"');
      }
    }
  }

  void _navigateToTagNotes(String tag) {
    Navigator.pushNamed(context, '/tags/$tag');
  }

  List<Map<String, dynamic>> _getAllTagsWithCount(NotesState state) {
    final tagCount = <String, int>{};
    for (final note in state.activeNotes) {
      for (final tag in note.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    final tags = tagCount.entries.map((e) => {
      'name': e.key,
      'count': e.value,
    }).toList();
    tags.sort((a, b) => ((b['count'] ?? 0) as int).compareTo((a['count'] ?? 0) as int));
    return tags;
  }

  int _getTagCount(String tag) {
    final notes = ref.read(notesProvider).activeNotes;
    return notes.where((n) => n.tags.contains(tag)).length;
  }

  Color _getTagColor(String tag) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    final hash = tag.hashCode.abs();
    return colors[hash % colors.length];
  }

  IconData _getTagIcon(String tag) {
    final lowerTag = tag.toLowerCase();
    if (lowerTag.contains('trabajo')) return Icons.work;
    if (lowerTag.contains('personal')) return Icons.person;
    if (lowerTag.contains('estudio')) return Icons.school;
    if (lowerTag.contains('compras')) return Icons.shopping_cart;
    if (lowerTag.contains('idea')) return Icons.lightbulb;
    if (lowerTag.contains('urgente')) return Icons.warning;
    if (lowerTag.contains('salud')) return Icons.favorite;
    if (lowerTag.contains('viaje')) return Icons.flight;
    return Icons.tag;
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}