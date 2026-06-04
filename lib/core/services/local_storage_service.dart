// lib/core/services/local_storage_service.dart
// Servicio de almacenamiento local (SharedPreferences)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote/models/note.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _preferences;

  // ============================================
  // INICIALIZACIÓN
  // ============================================
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // ============================================
  // NOTAS
  // ============================================
  Future<void> saveNotes(List<Note> notes) async {
    final notesJson = notes.map((n) => n.toJson()).toList();
    await _preferences?.setString('notes', jsonEncode(notesJson));
  }

  List<Note> getNotes() {
    final saved = _preferences?.getString('notes');
    if (saved == null) return [];
    final List<dynamic> notesJson = jsonDecode(saved);
    return notesJson.map((j) => Note.fromJson(j)).toList();
  }

  // ============================================
  // NOTAS ELIMINADAS
  // ============================================
  Future<void> saveDeletedNotes(List<Note> notes) async {
    final notesJson = notes.map((n) => n.toJson()).toList();
    await _preferences?.setString('deleted_notes', jsonEncode(notesJson));
  }

  List<Note> getDeletedNotes() {
    final saved = _preferences?.getString('deleted_notes');
    if (saved == null) return [];
    final List<dynamic> notesJson = jsonDecode(saved);
    return notesJson.map((j) => Note.fromJson(j)).toList();
  }

  // ============================================
  // PREFERENCIAS DEL USUARIO
  // ============================================
  Future<void> saveThemeMode(String mode) async {
    await _preferences?.setString('theme_mode', mode);
  }

  String getThemeMode() {
    return _preferences?.getString('theme_mode') ?? 'system';
  }

  Future<void> saveViewMode(String viewMode) async {
    await _preferences?.setString('view_mode', viewMode);
  }

  String getViewMode() {
    return _preferences?.getString('view_mode') ?? 'grid';
  }

  Future<void> saveSortOption(String sortOption) async {
    await _preferences?.setString('sort_option', sortOption);
  }

  String getSortOption() {
    return _preferences?.getString('sort_option') ?? 'newest';
  }

  // ============================================
  // ÚLTIMA SINCRONIZACIÓN
  // ============================================
  Future<void> saveLastSyncTime(String time) async {
    await _preferences?.setString('last_sync', time);
  }

  String? getLastSyncTime() {
    return _preferences?.getString('last_sync');
  }

  // ============================================
  // TAGS RECIENTES
  // ============================================
  Future<void> saveRecentTags(List<String> tags) async {
    await _preferences?.setString('recent_tags', jsonEncode(tags));
  }

  List<String> getRecentTags() {
    final saved = _preferences?.getString('recent_tags');
    if (saved == null) return [];
    return List<String>.from(jsonDecode(saved));
  }

  // ============================================
  // LIMPIEZA
  // ============================================
  Future<void> clearAll() async {
    await _preferences?.clear();
  }
}