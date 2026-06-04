// lib/core/utils/compression_utils.dart
// Utilidades de compresión y descompresión (GZIP)

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class CompressionUtils {
  // ============================================
  // COMPRIMIR STRING USANDO GZIP
  // ============================================
  static String compress(String data) {
    try {
      final bytes = utf8.encode(data);
      final compressed = GZipEncoder().encode(bytes);
      if (compressed == null) {
        throw Exception('Error al comprimir datos');
      }
      return base64.encode(compressed);
    } catch (e) {
      throw Exception('Error en compresión: $e');
    }
  }

  // ============================================
  // DESCOMPRIMIR STRING
  // ============================================
  static String decompress(String compressedData) {
    try {
      final bytes = base64.decode(compressedData);
      final decompressed = GZipDecoder().decodeBytes(bytes);
      return utf8.decode(decompressed);
    } catch (e) {
      throw Exception('Error en descompresión: $e');
    }
  }

  // ============================================
  // COMPRIMIR MAP A STRING COMPRIMIDO
  // ============================================
  static String compressMap(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return compress(jsonString);
  }

  // ============================================
  // DESCOMPRIMIR A MAP
  // ============================================
  static Map<String, dynamic> decompressToMap(String compressedData) {
    final jsonString = decompress(compressedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // ============================================
  // COMPRIMIR LISTA A STRING COMPRIMIDO
  // ============================================
  static String compressList(List<dynamic> data) {
    final jsonString = jsonEncode(data);
    return compress(jsonString);
  }

  // ============================================
  // DESCOMPRIMIR A LISTA
  // ============================================
  static List<dynamic> decompressToList(String compressedData) {
    final jsonString = decompress(compressedData);
    return jsonDecode(jsonString) as List<dynamic>;
  }

  // ============================================
  // CALCULAR RATIO DE COMPRESIÓN
  // ============================================
  static double getCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0;
    return (1 - compressedSize / originalSize) * 100;
  }

  // ============================================
  // FORMATO LEGIBLE DE BYTES
  // ============================================
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ============================================
  // OBTENER TAMAÑO ESTIMADO COMPRIMIDO
  // ============================================
  static int estimateCompressedSize(int originalSize) {
    // Estimación conservadora: 70% de reducción para textos
    return (originalSize * 0.3).floor();
  }

  // ============================================
  // CALCULAR AHORRO EN TÉRMINOS LEGIBLES
  // ============================================
  static String getCompressionSavings(int originalSize, int compressedSize) {
    final savings = originalSize - compressedSize;
    final savingsKB = (savings / 1024).toStringAsFixed(1);
    final ratio = getCompressionRatio(originalSize, compressedSize).toStringAsFixed(1);
    
    if (savings < 1024) {
      return '$savings bytes ($ratio%)';
    }
    return '$savingsKB KB ($ratio%)';
  }

  // ============================================
  // VERIFICAR SI LOS DATOS ESTÁN COMPRIMIDOS
  // ============================================
  static bool isCompressed(dynamic data) {
    if (data is! String) return false;
    // Los datos comprimidos en base64 tienen ciertas características
    return data.contains('%') || data.length > 100;
  }
}