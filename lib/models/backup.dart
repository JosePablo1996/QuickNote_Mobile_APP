// lib/models/backup.dart
// Modelos para backups - VERSIÓN COMPLETA CON copyWith

import 'package:quicknote/models/note.dart';

// ============================================
// BACKUP METADATA
// ============================================

class BackupMetadata {
  final String id;
  final String userId;
  final String fileName;
  final int fileSize;
  final int noteCount;
  final String version;
  final bool isAccumulative;
  final DateTime createdAt;
  final bool isLatest;
  final String? source;  // 'local' o 'cloud'
  final String? cloudId;

  const BackupMetadata({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileSize,
    required this.noteCount,
    required this.version,
    required this.isAccumulative,
    required this.createdAt,
    required this.isLatest,
    this.source,
    this.cloudId,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] ?? 0,
      noteCount: json['note_count'] ?? 0,
      version: json['version'] ?? '1.0.0',
      isAccumulative: json['is_accumulative'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isLatest: json['is_latest'] ?? false,
      source: json['source']?.toString(),
      cloudId: json['cloud_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'file_name': fileName,
    'file_size': fileSize,
    'note_count': noteCount,
    'version': version,
    'is_accumulative': isAccumulative,
    'created_at': createdAt.toIso8601String(),
    'is_latest': isLatest,
    if (source != null) 'source': source,
    if (cloudId != null) 'cloud_id': cloudId,
  };

  // ✅ Constructor para crear desde datos de API (cloud)
  factory BackupMetadata.fromCloudJson(Map<String, dynamic> json) {
    return BackupMetadata(
      id: 'cloud_${json['id']?.toString() ?? ''}',
      userId: json['user_id']?.toString() ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] ?? 0,
      noteCount: json['note_count'] ?? 0,
      version: json['version'] ?? '1.0.0',
      isAccumulative: json['is_accumulative'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isLatest: false,
      source: 'cloud',  // ✅ Forzar source = 'cloud'
      cloudId: json['id']?.toString(),
    );
  }

  // ✅ MÉTODO COPYWITH - CORREGIDO Y COMPLETO
  BackupMetadata copyWith({
    String? id,
    String? userId,
    String? fileName,
    int? fileSize,
    int? noteCount,
    String? version,
    bool? isAccumulative,
    DateTime? createdAt,
    bool? isLatest,
    String? source,
    String? cloudId,
  }) {
    return BackupMetadata(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      noteCount: noteCount ?? this.noteCount,
      version: version ?? this.version,
      isAccumulative: isAccumulative ?? this.isAccumulative,
      createdAt: createdAt ?? this.createdAt,
      isLatest: isLatest ?? this.isLatest,
      source: source ?? this.source,
      cloudId: cloudId ?? this.cloudId,
    );
  }

  @override
  String toString() {
    return 'BackupMetadata(id: $id, fileName: $fileName, source: $source, noteCount: $noteCount)';
  }
}

// ============================================
// BACKUP DATA
// ============================================

class BackupData {
  final String version;
  final DateTime timestamp;
  final int totalNotes;
  final List<Note> notes;
  final String? basedOn;
  final Map<String, dynamic>? metadata;

  BackupData({
    required this.version,
    required this.timestamp,
    required this.totalNotes,
    required this.notes,
    this.basedOn,
    this.metadata,
  });

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] ?? '1.0.0',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      totalNotes: json['total_notes'] ?? 0,
      notes: (json['notes'] as List?)
          ?.map((n) => Note.fromJson(n))
          .toList() ?? [],
      basedOn: json['based_on'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'total_notes': totalNotes,
    'notes': notes.map((n) => n.toJson()).toList(),
    if (basedOn != null) 'based_on': basedOn,
    if (metadata != null) 'metadata': metadata,
  };
}

// ============================================
// BACKUP LIMIT INFO
// ============================================

class BackupLimitInfo {
  final int current;
  final int max;
  final int remaining;
  final bool isFull;
  final bool isLow;
  final int totalSize;

  const BackupLimitInfo({
    required this.current,
    required this.max,
    required this.remaining,
    required this.isFull,
    required this.isLow,
    required this.totalSize,
  });

  factory BackupLimitInfo.fromJson(Map<String, dynamic> json) {
    return BackupLimitInfo(
      current: json['current'] ?? 0,
      max: json['max'] ?? 20,
      remaining: json['remaining'] ?? 20,
      isFull: json['is_full'] ?? false,
      isLow: json['is_low'] ?? false,
      totalSize: json['total_size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current,
    'max': max,
    'remaining': remaining,
    'is_full': isFull,
    'is_low': isLow,
    'total_size': totalSize,
  };
}

// ============================================
// BACKUP STATS
// ============================================

class BackupStats {
  final int totalNotes;
  final BackupMetadata? lastBackup;
  final int notesSinceLastBackup;
  final bool needsBackup;

  const BackupStats({
    required this.totalNotes,
    this.lastBackup,
    required this.notesSinceLastBackup,
    required this.needsBackup,
  });
}

// ============================================
// CLASES AUXILIARES PARA SINCRONIZACIÓN
// ============================================

class LocalBackupInfo {
  final String id;
  final String fileName;
  final int fileSize;
  final int noteCount;
  final DateTime createdAt;
  final String source;

  LocalBackupInfo({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.noteCount,
    required this.createdAt,
    this.source = 'local',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    'file_size': fileSize,
    'note_count': noteCount,
    'created_at': createdAt.toIso8601String(),
    'source': source,
  };
}

class SyncBackupsResponse {
  final int syncedCount;
  final int failedCount;
  final List<CloudBackupDownload> cloudBackupsToDownload;
  final String message;

  SyncBackupsResponse({
    required this.syncedCount,
    required this.failedCount,
    required this.cloudBackupsToDownload,
    required this.message,
  });

  factory SyncBackupsResponse.fromJson(Map<String, dynamic> json) {
    return SyncBackupsResponse(
      syncedCount: json['synced_count'] ?? 0,
      failedCount: json['failed_count'] ?? 0,
      cloudBackupsToDownload: (json['cloud_backups_to_download'] as List?)
          ?.map((b) => CloudBackupDownload.fromJson(b))
          .toList() ?? [],
      message: json['message'] ?? '',
    );
  }
}

class CloudBackupDownload {
  final String id;
  final String fileName;
  final int fileSize;
  final int noteCount;
  final DateTime createdAt;
  final Map<String, dynamic> notesData;

  CloudBackupDownload({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.noteCount,
    required this.createdAt,
    required this.notesData,
  });

  factory CloudBackupDownload.fromJson(Map<String, dynamic> json) {
    return CloudBackupDownload(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] ?? 0,
      noteCount: json['note_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      notesData: json['notes_data'] ?? {},
    );
  }
}