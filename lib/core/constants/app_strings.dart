// lib/core/constants/app_strings.dart
// Textos y mensajes de la aplicación

class AppStrings {
  // ============================================
  // NOMBRE DE LA APP
  // ============================================
  static const String appName = 'QuickNote';
  static const String appVersion = '2.6.0';
  static const String appDescription = 'Tus notas siempre contigo';
  static const String appAuthor = 'José Pablo Miranda Quintanilla';
  
  // ============================================
  // MENSAJES DE ÉXITO
  // ============================================
  static const String successNoteCreated = '✅ Nota creada exitosamente';
  static const String successNoteUpdated = '✏️ Nota actualizada exitosamente';
  static const String successNoteDeleted = '🗑️ Nota movida a la papelera';
  static const String successNoteRestored = '✨ Nota restaurada';
  static const String successNotePermanentlyDeleted = '⚠️ Nota eliminada permanentemente';
  static const String successFavoriteAdded = '⭐ Añadida a favoritos';
  static const String successFavoriteRemoved = '⭐ Quitada de favoritos';
  static const String successArchived = '📦 Nota archivada';
  static const String successUnarchived = '📦 Nota desarchivada';
  static const String successBackupCreated = '💾 Backup creado exitosamente';
  static const String successBackupRestored = '🔄 Backup restaurado';
  static const String successBackupDeleted = '🗑️ Backup eliminado';
  static const String successTrashEmptied = '🧹 Papelera vaciada';
  static const String successSync = '🔄 Sincronización completada';
  static const String successLogin = '🔐 ¡Bienvenido de vuelta!';
  static const String successRegister = '📝 ¡Registro exitoso!';
  static const String successProfileUpdated = '👤 Perfil actualizado';
  static const String successPasswordChanged = '🔑 Contraseña actualizada';
  static const String successTwoFactorEnabled = '🛡️ Autenticación 2FA activada';
  static const String successTwoFactorDisabled = '🔓 Autenticación 2FA desactivada';
  
  // ============================================
  // MENSAJES DE ERROR
  // ============================================
  static const String errorLoadNotes = 'Error al cargar las notas';
  static const String errorCreateNote = 'Error al crear la nota';
  static const String errorUpdateNote = 'Error al actualizar la nota';
  static const String errorDeleteNote = 'Error al eliminar la nota';
  static const String errorRestoreNote = 'Error al restaurar la nota';
  static const String errorToggleFavorite = 'Error al cambiar favorito';
  static const String errorToggleArchive = 'Error al archivar/desarchivar';
  static const String errorLoadBackups = 'Error al cargar los backups';
  static const String errorCreateBackup = 'Error al crear el backup';
  static const String errorRestoreBackup = 'Error al restaurar el backup';
  static const String errorDeleteBackup = 'Error al eliminar el backup';
  static const String errorSync = 'Error al sincronizar';
  static const String errorNetwork = 'Error de conexión. Modo offline activado';
  static const String errorUnknown = 'Ha ocurrido un error inesperado';
  static const String errorLogin = 'Error al iniciar sesión';
  static const String errorRegister = 'Error al registrarse';
  static const String errorLogout = 'Error al cerrar sesión';
  static const String errorUpload = 'Error al subir el archivo';
  static const String errorInvalidCredentials = 'Credenciales inválidas';
  static const String errorEmailInUse = 'El email ya está registrado';
  static const String errorWeakPassword = 'La contraseña es demasiado débil';
  static const String errorInvalidOtp = 'Código OTP inválido o expirado';
  static const String errorTwoFactorInvalid = 'Código 2FA inválido';
  
  // ============================================
  // MENSAJES DE CONFIRMACIÓN
  // ============================================
  static String confirmDeleteNote(String title) => '¿Eliminar la nota "$title"?';
  static String confirmDeleteMultiple(int count) => '¿Eliminar $count nota${count != 1 ? 's' : ''}?';
  static String confirmDeletePermanently(String title) => '¿Eliminar permanentemente "$title"? Esta acción no se puede deshacer.';
  static String confirmEmptyTrash(int count) => '¿Vaciar la papelera? Se eliminarán permanentemente $count nota${count != 1 ? 's' : ''}.';
  static String confirmRestoreNote(String title) => '¿Restaurar la nota "$title"?';
  static String confirmLogout = '¿Cerrar sesión?';
  static String confirmLeavePage = 'Tienes cambios sin guardar. ¿Seguro que quieres salir?';
  
  // ============================================
  // PLACEHOLDERS
  // ============================================
  static const String placeholderSearch = 'Buscar notas...';
  static const String placeholderTitle = 'Título de la nota';
  static const String placeholderContent = 'Escribe tu nota aquí...';
  static const String placeholderTag = 'Nueva etiqueta';
  static const String placeholderEmail = 'correo@ejemplo.com';
  static const String placeholderPassword = '********';
  static const String placeholderName = 'Nombre completo';
  static const String placeholderConfirmPassword = 'Confirmar contraseña';
  
  // ============================================
  // MENSAJES DE ESTADO VACÍO
  // ============================================
  static const String emptyNotes = 'No hay notas. ¡Crea tu primera nota!';
  static const String emptyFavorites = 'No hay notas favoritas. Marca algunas con ⭐';
  static const String emptyArchived = 'No hay notas archivadas';
  static const String emptyTrash = 'La papelera está vacía';
  static const String emptyTags = 'No hay etiquetas. Crea una desde el formulario de notas';
  static String emptySearch(String query) => 'No se encontraron resultados para "$query"';
  static const String emptyBackups = 'No hay backups. Crea tu primer backup';
  static const String emptyCalendar = 'No hay notas en este mes';
  
  // ============================================
  // ETIQUETAS DE UI
  // ============================================
  static const String labelLogin = 'Iniciar Sesión';
  static const String labelRegister = 'Registrarse';
  static const String labelLogout = 'Cerrar Sesión';
  static const String labelSave = 'Guardar';
  static const String labelCancel = 'Cancelar';
  static const String labelDelete = 'Eliminar';
  static const String labelEdit = 'Editar';
  static const String labelCreate = 'Crear';
  static const String labelUpdate = 'Actualizar';
  static const String labelBack = 'Volver';
  static const String labelNext = 'Siguiente';
  static const String labelConfirm = 'Confirmar';
  static const String labelRetry = 'Reintentar';
  static const String labelRefresh = 'Actualizar';
  static const String labelSync = 'Sincronizar';
  static const String labelExport = 'Exportar';
  static const String labelImport = 'Importar';
  static const String labelShare = 'Compartir';
  static const String labelCopy = 'Copiar';
  static const String labelPrint = 'Imprimir';
  
  // ============================================
  // TABS Y SECCIONES
  // ============================================
  static const String tabAllNotes = 'Todas las notas';
  static const String tabFavorites = 'Favoritas';
  static const String tabArchived = 'Archivadas';
  static const String tabTrash = 'Papelera';
  static const String tabTags = 'Etiquetas';
  static const String tabCalendar = 'Calendario';
  static const String tabSettings = 'Configuración';
  static const String tabProfile = 'Perfil';
  static const String tabBackup = 'Copias de Seguridad';
  static const String tabHelp = 'Ayuda';
  static const String tabDeveloper = 'Desarrollador';
  
  // ============================================
  // SEGURIDAD
  // ============================================
  static const String securityBiometric = 'Autenticación Biométrica';
  static const String securityTwoFactor = 'Autenticación de Dos Factores (2FA)';
  static const String securityPasskey = 'Claves de acceso (Passkeys)';
  static const String securityChangePassword = 'Cambiar contraseña';
  static const String securityForgotPassword = '¿Olvidaste tu contraseña?';
  
  // ============================================
  // BACKUP
  // ============================================
  static const String backupLocal = 'Backup Local';
  static const String backupCloud = 'Backup en la Nube';
  static const String backupCreate = 'Crear Backup';
  static const String backupRestore = 'Restaurar Backup';
  static const String backupDelete = 'Eliminar Backup';
  static const String backupAuto = 'Backup Automático';
  static const String backupSelective = 'Backup Selectivo';
  static const String backupLimitReached = 'Límite de backups alcanzado';
  static const String backupLimitInfo = 'Máximo 20 backups por usuario';
}