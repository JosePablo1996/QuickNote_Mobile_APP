// lib/models/user.dart
// Modelo de usuario

class User {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String? banner;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final bool isActive;
  final UserSettings? settings;
  final UserStats? stats;

  User({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.banner,
    this.role = 'user',
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.isActive = true,
    this.settings,
    this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['full_name'],
      avatar: json['avatar'] ?? json['avatar_url'],
      banner: json['banner'] ?? json['banner_url'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      isActive: json['is_active'] ?? true,
      settings: json['settings'] != null ? UserSettings.fromJson(json['settings']) : null,
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (name != null) 'name': name,
    if (avatar != null) 'avatar': avatar,
    if (banner != null) 'banner': banner,
    'role': role,
    'created_at': createdAt.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
    'is_active': isActive,
    if (settings != null) 'settings': settings!.toJson(),
    if (stats != null) 'stats': stats!.toJson(),
  };

  String get displayName => name ?? email.split('@').first;
  
  String get initials => _getInitials(displayName);

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ✅ MÉTODO COPYWITH COMPLETO Y CORREGIDO
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? banner,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    bool? isActive,
    UserSettings? settings,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      banner: banner ?? this.banner,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
    );
  }
}

// ============================================
// USER SETTINGS
// ============================================

class UserSettings {
  final String theme;
  final String language;
  final bool notifications;
  final String defaultNoteColor;
  final bool autoSave;
  final String defaultView;
  final String sortBy;
  final String sortOrder;

  UserSettings({
    this.theme = 'system',
    this.language = 'es',
    this.notifications = true,
    this.defaultNoteColor = '#3B82F6',
    this.autoSave = true,
    this.defaultView = 'grid',
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'es',
      notifications: json['notifications'] ?? true,
      defaultNoteColor: json['default_note_color'] ?? '#3B82F6',
      autoSave: json['auto_save'] ?? true,
      defaultView: json['default_view'] ?? 'grid',
      sortBy: json['sort_by'] ?? 'created_at',
      sortOrder: json['sort_order'] ?? 'desc',
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'language': language,
    'notifications': notifications,
    'default_note_color': defaultNoteColor,
    'auto_save': autoSave,
    'default_view': defaultView,
    'sort_by': sortBy,
    'sort_order': sortOrder,
  };

  UserSettings copyWith({
    String? theme,
    String? language,
    bool? notifications,
    String? defaultNoteColor,
    bool? autoSave,
    String? defaultView,
    String? sortBy,
    String? sortOrder,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      defaultNoteColor: defaultNoteColor ?? this.defaultNoteColor,
      autoSave: autoSave ?? this.autoSave,
      defaultView: defaultView ?? this.defaultView,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

// ============================================
// USER STATS
// ============================================

class UserStats {
  final int totalNotes;
  final int totalFavorites;
  final int totalArchived;
  final int totalDeleted;
  final int totalTags;
  final int notesCreatedToday;
  final int notesCreatedThisWeek;
  final int notesCreatedThisMonth;
  final double averageNoteLength;
  final List<MostUsedTag> mostUsedTags;
  final DateTime lastActive;

  UserStats({
    this.totalNotes = 0,
    this.totalFavorites = 0,
    this.totalArchived = 0,
    this.totalDeleted = 0,
    this.totalTags = 0,
    this.notesCreatedToday = 0,
    this.notesCreatedThisWeek = 0,
    this.notesCreatedThisMonth = 0,
    this.averageNoteLength = 0,
    this.mostUsedTags = const [],
    required this.lastActive,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalNotes: json['total_notes'] ?? 0,
      totalFavorites: json['total_favorites'] ?? 0,
      totalArchived: json['total_archived'] ?? 0,
      totalDeleted: json['total_deleted'] ?? 0,
      totalTags: json['total_tags'] ?? 0,
      notesCreatedToday: json['notes_created_today'] ?? 0,
      notesCreatedThisWeek: json['notes_created_this_week'] ?? 0,
      notesCreatedThisMonth: json['notes_created_this_month'] ?? 0,
      averageNoteLength: (json['average_note_length'] ?? 0).toDouble(),
      mostUsedTags: (json['most_used_tags'] as List?)
          ?.map((t) => MostUsedTag.fromJson(t))
          .toList() ?? [],
      lastActive: DateTime.parse(json['last_active'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_notes': totalNotes,
    'total_favorites': totalFavorites,
    'total_archived': totalArchived,
    'total_deleted': totalDeleted,
    'total_tags': totalTags,
    'notes_created_today': notesCreatedToday,
    'notes_created_this_week': notesCreatedThisWeek,
    'notes_created_this_month': notesCreatedThisMonth,
    'average_note_length': averageNoteLength,
    'most_used_tags': mostUsedTags.map((t) => t.toJson()).toList(),
    'last_active': lastActive.toIso8601String(),
  };

  UserStats copyWith({
    int? totalNotes,
    int? totalFavorites,
    int? totalArchived,
    int? totalDeleted,
    int? totalTags,
    int? notesCreatedToday,
    int? notesCreatedThisWeek,
    int? notesCreatedThisMonth,
    double? averageNoteLength,
    List<MostUsedTag>? mostUsedTags,
    DateTime? lastActive,
  }) {
    return UserStats(
      totalNotes: totalNotes ?? this.totalNotes,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      totalArchived: totalArchived ?? this.totalArchived,
      totalDeleted: totalDeleted ?? this.totalDeleted,
      totalTags: totalTags ?? this.totalTags,
      notesCreatedToday: notesCreatedToday ?? this.notesCreatedToday,
      notesCreatedThisWeek: notesCreatedThisWeek ?? this.notesCreatedThisWeek,
      notesCreatedThisMonth: notesCreatedThisMonth ?? this.notesCreatedThisMonth,
      averageNoteLength: averageNoteLength ?? this.averageNoteLength,
      mostUsedTags: mostUsedTags ?? this.mostUsedTags,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

// ============================================
// MOST USED TAG
// ============================================

class MostUsedTag {
  final String tag;
  final int count;

  MostUsedTag({
    required this.tag,
    required this.count,
  });

  factory MostUsedTag.fromJson(Map<String, dynamic> json) {
    return MostUsedTag(
      tag: json['tag'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'count': count,
  };

  MostUsedTag copyWith({
    String? tag,
    int? count,
  }) {
    return MostUsedTag(
      tag: tag ?? this.tag,
      count: count ?? this.count,
    );
  }
}