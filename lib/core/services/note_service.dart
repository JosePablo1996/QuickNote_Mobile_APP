// lib/core/services/note_service.dart
// Servicio de notas (CRUD) - VERSIÓN CORREGIDA CON URLS DIRECTAS

import 'package:flutter/foundation.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/core/constants/endpoints.dart';
import 'package:quicknote/models/note.dart';

class _NoteServiceLogger {
  static void info(String message) => debugPrint('ℹ️ [NoteService] $message');
  static void success(String message) => debugPrint('✅ [NoteService] $message');
  static void warning(String message) => debugPrint('⚠️ [NoteService] $message');
  static void error(String message) => debugPrint('❌ [NoteService] $message');
}

class NoteService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<List<Note>> getNotes({bool deleted = false}) async {
    _NoteServiceLogger.info('Obteniendo notas (deleted: $deleted)');
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL CON SLASH FINAL
      final response = await dio.get(
        '/notes/',
        queryParameters: {'deleted': deleted},
      );
      if (response.statusCode == 200) {
        final notes = (response.data as List).map((json) => Note.fromJson(json)).toList();
        _NoteServiceLogger.success('${notes.length} notas obtenidas');
        return notes;
      }
      return [];
    } catch (e) {
      _NoteServiceLogger.error('Error obteniendo notas: $e');
      return [];
    }
  }

  Future<List<Note>> getActiveNotes() async {
    final allNotes = await getNotes(deleted: false);
    return allNotes.where((note) => !note.isArchived).toList();
  }

  Future<List<Note>> getArchivedNotes() async {
    final allNotes = await getNotes(deleted: false);
    return allNotes.where((note) => note.isArchived).toList();
  }

  Future<List<Note>> getDeletedNotes() async => await getNotes(deleted: true);

  Future<Note?> getNoteById(String id) async {
    _NoteServiceLogger.info('Obteniendo nota: $id');
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL CON SLASH FINAL
      final response = await dio.get('/notes/$id/');
      if (response.statusCode == 200) {
        final note = Note.fromJson(response.data);
        _NoteServiceLogger.success('Nota obtenida: ${note.title}');
        return note;
      }
      return null;
    } catch (e) {
      _NoteServiceLogger.error('Error obteniendo nota: $e');
      return null;
    }
  }

  Future<Note?> createNote(NoteCreate note) async {
    _NoteServiceLogger.info('Creando nueva nota: ${note.title}');
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL CON SLASH FINAL - CLAVE PARA EVITAR 307
      final response = await dio.post('/notes/', data: note.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdNote = Note.fromJson(response.data);
        _NoteServiceLogger.success('Nota creada: ${createdNote.title}');
        return createdNote;
      }
      return null;
    } catch (e) {
      _NoteServiceLogger.error('Error creando nota: $e');
      return null;
    }
  }

  Future<Note?> updateNote(String id, NoteUpdate note) async {
    _NoteServiceLogger.info('Actualizando nota: $id');
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL CON SLASH FINAL
      final response = await dio.put('/notes/$id/', data: note.toJson());
      if (response.statusCode == 200) {
        final updatedNote = Note.fromJson(response.data);
        _NoteServiceLogger.success('Nota actualizada: ${updatedNote.title}');
        return updatedNote;
      }
      return null;
    } catch (e) {
      _NoteServiceLogger.error('Error actualizando nota: $e');
      return null;
    }
  }

  Future<Note?> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note == null) return null;
    return await updateNote(id, NoteUpdate(isFavorite: !note.isFavorite));
  }

  Future<Note?> toggleArchive(String id) async {
    final note = await getNoteById(id);
    if (note == null) return null;
    return await updateNote(id, NoteUpdate(isArchived: !note.isArchived));
  }

  Future<bool> deleteNote(String id, {bool permanent = false}) async {
    if (permanent) {
      _NoteServiceLogger.info('Eliminando nota permanentemente: $id');
      return await _permanentlyDeleteNote(id);
    } else {
      _NoteServiceLogger.info('Soft delete - moviendo a papelera: $id');
      return await _softDeleteNote(id);
    }
  }

  Future<bool> _softDeleteNote(String id) async {
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL CON SLASH FINAL
      final response = await dio.delete('/notes/$id/');
      if (response.statusCode == 200) {
        _NoteServiceLogger.success('Nota movida a papelera: $id');
        return true;
      }
      return false;
    } catch (e) {
      _NoteServiceLogger.error('Error en soft delete: $e');
      return false;
    }
  }

  Future<bool> _permanentlyDeleteNote(String id) async {
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL DIRECTA
      final response = await dio.delete('/notes/$id/permanent');
      if (response.statusCode == 200) {
        _NoteServiceLogger.success('Nota eliminada permanentemente: $id');
        return true;
      }
      return false;
    } catch (e) {
      _NoteServiceLogger.error('Error en eliminación permanente: $e');
      return false;
    }
  }

  Future<bool> permanentlyDeleteNote(String id) async => await deleteNote(id, permanent: true);

  Future<bool> emptyTrash() async {
    _NoteServiceLogger.info('Vaciando papelera completa...');
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL DIRECTA
      final response = await dio.delete('/notes/trash/empty');
      if (response.statusCode == 200) {
        _NoteServiceLogger.success('Papelera vaciada correctamente');
        return true;
      }
      return false;
    } catch (e) {
      _NoteServiceLogger.error('Error vaciando papelera: $e');
      return false;
    }
  }

  Future<Note?> restoreNote(String id) async {
    _NoteServiceLogger.info('Restaurando nota: $id');
    try {
      final dio = await _apiClient.dio;
      // ✅ USAR URL DIRECTA
      final response = await dio.post('/notes/$id/restore');
      if (response.statusCode == 200) {
        final updatedNote = await getNoteById(id);
        if (updatedNote != null) {
          _NoteServiceLogger.success('Nota restaurada: $id');
          return updatedNote;
        }
      }
      return null;
    } catch (e) {
      _NoteServiceLogger.error('Error restaurando nota: $e');
      return null;
    }
  }

  Future<Map<String, int>> deleteMultipleNotes(List<String> ids) async {
    int successCount = 0;
    for (final id in ids) {
      if (await deleteNote(id, permanent: false)) successCount++;
    }
    return {'success': successCount, 'failed': ids.length - successCount};
  }

  Future<Map<String, int>> permanentlyDeleteMultipleNotes(List<String> ids) async {
    int successCount = 0;
    for (final id in ids) {
      if (await permanentlyDeleteNote(id)) successCount++;
    }
    return {'success': successCount, 'failed': ids.length - successCount};
  }

  Future<Map<String, int>> restoreMultipleNotes(List<String> ids) async {
    int successCount = 0;
    for (final id in ids) {
      if (await restoreNote(id) != null) successCount++;
    }
    return {'success': successCount, 'failed': ids.length - successCount};
  }

  Future<List<Note>> syncNotes(List<Note> notes) async {
    _NoteServiceLogger.info('Sincronizando ${notes.length} notas');
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post('/notes/sync', data: notes.map((n) => n.toJson()).toList());
      if (response.statusCode == 200) {
        final syncedNotes = (response.data as List).map((json) => Note.fromJson(json)).toList();
        _NoteServiceLogger.success('${syncedNotes.length} notas sincronizadas');
        return syncedNotes;
      }
      return [];
    } catch (e) {
      _NoteServiceLogger.error('Error sincronizando notas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNoteStats() async {
    final activeNotes = await getActiveNotes();
    final archivedNotes = await getArchivedNotes();
    final deletedNotes = await getDeletedNotes();
    return {
      'total': activeNotes.length,
      'archived': archivedNotes.length,
      'deleted': deletedNotes.length,
      'favorites': activeNotes.where((n) => n.isFavorite).length,
      'totalTags': activeNotes.expand((n) => n.tags).toSet().length,
    };
  }
}

final noteService = NoteService();