// lib/core/services/storage_service.dart
// Servicio para interactuar con Supabase Storage

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;  // ✅ AGREGAR ESTE IMPORT
import 'package:quicknote/core/utils/token_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // URLs directas de Supabase (públicas)
  static const String _supabaseStorage = 'https://hrrlcxxkboaamrzhntns.supabase.co/storage/v1/object/public';

  Future<Map<String, String?>> fetchUserImages(String userId) async {
    try {
      debugPrint('🔍 [StorageService] Buscando imágenes para usuario: $userId');
      
      // Primero, intentar obtener URLs guardadas
      final savedAvatar = await tokenStorage.getUserAvatar();
      final savedBanner = await tokenStorage.getUserBanner();
      
      if (savedBanner != null && savedBanner.isNotEmpty) {
        debugPrint('✅ [StorageService] Banner desde storage: $savedBanner');
        return {
          'avatar': savedAvatar,
          'banner': savedBanner,
        };
      }
      
      // URLs conocidas del usuario (funcionan en la web)
      final knownBannerUrl = '$_supabaseStorage/banners/$userId/1775032503-263cd994-d213-4303-98a7-c103a2314333.webp';
      final knownAvatarUrl = '$_supabaseStorage/avatars/$userId/1775032498-c80227e8-3a50-4324-a9af-97c37a4f8216.jpg';
      
      // Verificar si la URL del banner existe
      final bannerExists = await _checkUrlExists(knownBannerUrl);
      if (bannerExists) {
        debugPrint('✅ [StorageService] Banner encontrado: $knownBannerUrl');
        await tokenStorage.saveUserBanner(knownBannerUrl);
        return {
          'avatar': savedAvatar,
          'banner': knownBannerUrl,
        };
      }
      
      // Buscar banner por patrones comunes
      final possibleBannerNames = [
        'banner.webp',
        'banner.jpg',
        'banner.png',
        'cover.webp',
        'cover.jpg',
      ];
      
      String? bannerUrl;
      for (final name in possibleBannerNames) {
        final testUrl = '$_supabaseStorage/banners/$userId/$name';
        final exists = await _checkUrlExists(testUrl);
        if (exists) {
          bannerUrl = testUrl;
          debugPrint('✅ [StorageService] Banner encontrado: $bannerUrl');
          break;
        }
      }
      
      if (bannerUrl != null) {
        await tokenStorage.saveUserBanner(bannerUrl);
      }
      
      return {
        'avatar': savedAvatar,
        'banner': bannerUrl,
      };
    } catch (e) {
      debugPrint('❌ [StorageService] Error general: $e');
      return {'avatar': null, 'banner': null};
    }
  }
  
  Future<bool> _checkUrlExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Método para construir URL después de subir un avatar
  String buildAvatarUrl(String userId, String fileName) {
    return '$_supabaseStorage/avatars/$userId/$fileName';
  }
  
  // Método para construir URL después de subir un banner
  String buildBannerUrl(String userId, String fileName) {
    return '$_supabaseStorage/banners/$userId/$fileName';
  }
  
  // Guardar URLs después de subir exitosamente
  Future<void> saveAvatarUrl(String url) async {
    await tokenStorage.saveUserAvatar(url);
  }
  
  Future<void> saveBannerUrl(String url) async {
    await tokenStorage.saveUserBanner(url);
  }
}