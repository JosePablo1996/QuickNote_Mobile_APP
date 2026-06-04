// lib/core/utils/date_utils.dart
// Utilidades para manejo de fechas

class DateUtils {
  // ============================================
  // FORMATO DD/MM/YYYY
  // ============================================
  static String formatDate(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
  }

  static String formatDateFromString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return formatDate(date);
    } catch (e) {
      return dateStr.substring(0, 10);
    }
  }

  // ============================================
  // FORMATO DD/MM/YYYY HH:MM
  // ============================================
  static String formatDateTime(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year} ${_pad(date.hour)}:${_pad(date.minute)}';
  }

  static String formatDateTimeFromString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return formatDateTime(date);
    } catch (e) {
      return dateStr;
    }
  }

  // ============================================
  // FORMATO HH:MM
  // ============================================
  static String formatTime(DateTime date) {
    return '${_pad(date.hour)}:${_pad(date.minute)}';
  }

  // ============================================
  // TIEMPO RELATIVO (hoy, ayer, hace X días)
  // ============================================
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks semana${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months mes${months > 1 ? 'es' : ''}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years año${years > 1 ? 's' : ''}';
    }
  }

  static String getRelativeTimeFromString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return getRelativeTime(date);
    } catch (e) {
      return 'Fecha desconocida';
    }
  }

  // ============================================
  // VERIFICAR SI ES HOY
  // ============================================
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // ============================================
  // VERIFICAR SI ES AYER
  // ============================================
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  // ============================================
  // VERIFICAR SI ES DE ESTA SEMANA
  // ============================================
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return date.isAfter(weekAgo) && date.isBefore(now);
  }

  // ============================================
  // VERIFICAR SI ES DE ESTE MES
  // ============================================
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // ============================================
  // FORMATO PARA NOMBRE DE ARCHIVO
  // ============================================
  static String formatForFilename(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}_${_pad(date.hour)}-${_pad(date.minute)}';
  }

  // ============================================
  // OBTENER DÍAS DEL MES
  // ============================================
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // ============================================
  // OBTENER PRIMER DÍA DEL MES
  // ============================================
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // ============================================
  // OBTENER ÚLTIMO DÍA DEL MES
  // ============================================
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================
  static String _pad(int value) => value.toString().padLeft(2, '0');
}