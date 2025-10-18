import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple localization service without flutter_gen dependency
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => _getLocalizedValue('appTitle');
  String get home => _getLocalizedValue('home');
  String get matches => _getLocalizedValue('matches');
  String get report => _getLocalizedValue('report');
  String get profile => _getLocalizedValue('profile');
  String get login => _getLocalizedValue('login');
  String get signup => _getLocalizedValue('signup');
  String get logout => _getLocalizedValue('logout');
  String get email => _getLocalizedValue('email');
  String get password => _getLocalizedValue('password');
  String get confirmPassword => _getLocalizedValue('confirmPassword');
  String get forgotPassword => _getLocalizedValue('forgotPassword');
  String get dontHaveAccount => _getLocalizedValue('dontHaveAccount');
  String get alreadyHaveAccount => _getLocalizedValue('alreadyHaveAccount');
  String get lostItem => _getLocalizedValue('lostItem');
  String get foundItem => _getLocalizedValue('foundItem');
  String get title => _getLocalizedValue('title');
  String get description => _getLocalizedValue('description');
  String get category => _getLocalizedValue('category');
  String get location => _getLocalizedValue('location');
  String get dateLost => _getLocalizedValue('dateLost');
  String get dateFound => _getLocalizedValue('dateFound');
  String get contactOwner => _getLocalizedValue('contactOwner');
  String get share => _getLocalizedValue('share');
  String get save => _getLocalizedValue('save');
  String get cancel => _getLocalizedValue('cancel');
  String get delete => _getLocalizedValue('delete');
  String get edit => _getLocalizedValue('edit');
  String get search => _getLocalizedValue('search');
  String get filter => _getLocalizedValue('filter');
  String get noItemsFound => _getLocalizedValue('noItemsFound');
  String get beFirstToReport => _getLocalizedValue('beFirstToReport');
  String get noLostItemsYet => _getLocalizedValue('noLostItemsYet');
  String get noFoundItemsYet => _getLocalizedValue('noFoundItemsYet');
  String get loading => _getLocalizedValue('loading');
  String get error => _getLocalizedValue('error');
  String get retry => _getLocalizedValue('retry');
  String get success => _getLocalizedValue('success');
  String get failed => _getLocalizedValue('failed');
  String get settings => _getLocalizedValue('settings');
  String get language => _getLocalizedValue('language');
  String get notifications => _getLocalizedValue('notifications');
  String get privacy => _getLocalizedValue('privacy');
  String get terms => _getLocalizedValue('terms');
  String get support => _getLocalizedValue('support');
  String get about => _getLocalizedValue('about');
  String get version => _getLocalizedValue('version');
  String get darkMode => _getLocalizedValue('darkMode');
  String get lightMode => _getLocalizedValue('lightMode');
  String get myItems => _getLocalizedValue('myItems');
  String get active => _getLocalizedValue('active');
  String get resolved => _getLocalizedValue('resolved');
  String get drafts => _getLocalizedValue('drafts');
  String get resolve => _getLocalizedValue('resolve');
  String get markAsResolved => _getLocalizedValue('markAsResolved');
  String get areYouSureResolve => _getLocalizedValue('areYouSureResolve');
  String get itemResolved => _getLocalizedValue('itemResolved');
  String get failedToResolve => _getLocalizedValue('failedToResolve');
  String get chat => _getLocalizedValue('chat');
  String get conversations => _getLocalizedValue('conversations');
  String get sendMessage => _getLocalizedValue('sendMessage');
  String get typeMessage => _getLocalizedValue('typeMessage');
  String get archive => _getLocalizedValue('archive');
  String get block => _getLocalizedValue('block');
  String get unblock => _getLocalizedValue('unblock');
  String get deleteConversation => _getLocalizedValue('deleteConversation');
  String get areYouSureDelete => _getLocalizedValue('areYouSureDelete');
  String get conversationDeleted => _getLocalizedValue('conversationDeleted');
  String get failedToDelete => _getLocalizedValue('failedToDelete');
  String get userBlocked => _getLocalizedValue('userBlocked');
  String get userUnblocked => _getLocalizedValue('userUnblocked');
  String get conversationArchived => _getLocalizedValue('conversationArchived');
  String get profilePicture => _getLocalizedValue('profilePicture');
  String get takePhoto => _getLocalizedValue('takePhoto');
  String get chooseFromGallery => _getLocalizedValue('chooseFromGallery');
  String get removePhoto => _getLocalizedValue('removePhoto');
  String get exportData => _getLocalizedValue('exportData');
  String get deleteAccount => _getLocalizedValue('deleteAccount');
  String get areYouSureDeleteAccount =>
      _getLocalizedValue('areYouSureDeleteAccount');
  String get accountDeleted => _getLocalizedValue('accountDeleted');
  String get dataExported => _getLocalizedValue('dataExported');
  String get profilePictureUpdated =>
      _getLocalizedValue('profilePictureUpdated');
  String get profilePictureRemoved =>
      _getLocalizedValue('profilePictureRemoved');
  String get enterEmail => _getLocalizedValue('enterEmail');
  String get passwordResetSent => _getLocalizedValue('passwordResetSent');
  String get sendSupportMessage => _getLocalizedValue('sendSupportMessage');
  String get message => _getLocalizedValue('message');
  String get messageSent => _getLocalizedValue('messageSent');
  String get failedToSendMessage => _getLocalizedValue('failedToSendMessage');
  String get itemDetails => _getLocalizedValue('itemDetails');
  String get distance => _getLocalizedValue('distance');
  String get calculating => _getLocalizedValue('calculating');
  String get locationDisabled => _getLocalizedValue('locationDisabled');
  String get permissionDenied => _getLocalizedValue('permissionDenied');
  String get permissionDeniedForever =>
      _getLocalizedValue('permissionDeniedForever');
  String get locationUnavailable => _getLocalizedValue('locationUnavailable');
  String get errorCalculating => _getLocalizedValue('errorCalculating');
  String get itemDetailsCopied => _getLocalizedValue('itemDetailsCopied');
  String get failedToShare => _getLocalizedValue('failedToShare');
  String get mapUrlCopied => _getLocalizedValue('mapUrlCopied');
  String get failedToOpenMaps => _getLocalizedValue('failedToOpenMaps');
  String get locationCoordinatesNotAvailable =>
      _getLocalizedValue('locationCoordinatesNotAvailable');
  String get contactFeatureComingSoon =>
      _getLocalizedValue('contactFeatureComingSoon');
  String get failedToStartConversation =>
      _getLocalizedValue('failedToStartConversation');
  String get failedToContactOwner => _getLocalizedValue('failedToContactOwner');
  String get noNotifications => _getLocalizedValue('noNotifications');
  String get youreAllCaughtUp => _getLocalizedValue('youreAllCaughtUp');
  String get markAllRead => _getLocalizedValue('markAllRead');
  String get justNow => _getLocalizedValue('justNow');
  String get minutesAgo => _getLocalizedValue('minutesAgo');
  String get hoursAgo => _getLocalizedValue('hoursAgo');
  String get yesterday => _getLocalizedValue('yesterday');
  String get daysAgo => _getLocalizedValue('daysAgo');
  String get reportLostItem => _getLocalizedValue('reportLostItem');
  String get reportFoundItem => _getLocalizedValue('reportFoundItem');
  String get itemType => _getLocalizedValue('itemType');
  String get selectCategory => _getLocalizedValue('selectCategory');
  String get addPhotos => _getLocalizedValue('addPhotos');
  String get itemReported => _getLocalizedValue('itemReported');
  String get failedToReportItem => _getLocalizedValue('failedToReportItem');
  String get selectDate => _getLocalizedValue('selectDate');
  String get selectTime => _getLocalizedValue('selectTime');
  String get electronics => _getLocalizedValue('electronics');
  String get clothing => _getLocalizedValue('clothing');
  String get accessories => _getLocalizedValue('accessories');
  String get documents => _getLocalizedValue('documents');
  String get keys => _getLocalizedValue('keys');
  String get bags => _getLocalizedValue('bags');
  String get books => _getLocalizedValue('books');
  String get toys => _getLocalizedValue('toys');
  String get sports => _getLocalizedValue('sports');
  String get other => _getLocalizedValue('other');

  String _getLocalizedValue(String key) {
    final translations = _getTranslations();
    return translations[key] ?? key;
  }

  Map<String, String> _getTranslations() {
    switch (locale.languageCode) {
      case 'es':
        return _spanishTranslations;
      case 'fr':
        return _frenchTranslations;
      case 'de':
        return _germanTranslations;
      case 'it':
        return _italianTranslations;
      case 'pt':
        return _portugueseTranslations;
      case 'ru':
        return _russianTranslations;
      case 'zh':
        return _chineseTranslations;
      case 'ja':
        return _japaneseTranslations;
      case 'ko':
        return _koreanTranslations;
      default:
        return _englishTranslations;
    }
  }

  static const Map<String, String> _englishTranslations = {
    'appTitle': 'Lost & Found',
    'home': 'Home',
    'matches': 'Matches',
    'report': 'Report',
    'profile': 'Profile',
    'login': 'Login',
    'signup': 'Sign Up',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'forgotPassword': 'Forgot Password?',
    'dontHaveAccount': 'Don\'t have an account?',
    'alreadyHaveAccount': 'Already have an account?',
    'lostItem': 'Lost Item',
    'foundItem': 'Found Item',
    'title': 'Title',
    'description': 'Description',
    'category': 'Category',
    'location': 'Location',
    'dateLost': 'Date Lost',
    'dateFound': 'Date Found',
    'contactOwner': 'Contact Owner',
    'share': 'Share',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'filter': 'Filter',
    'noItemsFound': 'No items found',
    'beFirstToReport': 'Be the first to report an item!',
    'noLostItemsYet': 'No lost items yet',
    'noFoundItemsYet': 'No found items yet',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'success': 'Success',
    'failed': 'Failed',
    'settings': 'Settings',
    'language': 'Language',
    'notifications': 'Notifications',
    'privacy': 'Privacy',
    'terms': 'Terms',
    'support': 'Support',
    'about': 'About',
    'version': 'Version',
    'darkMode': 'Dark Mode',
    'lightMode': 'Light Mode',
    'myItems': 'My Items',
    'active': 'Active',
    'resolved': 'Resolved',
    'drafts': 'Drafts',
    'resolve': 'Resolve',
    'markAsResolved': 'Mark as Resolved',
    'areYouSureResolve': 'Are you sure you want to mark this item as resolved?',
    'itemResolved': 'Item marked as resolved',
    'failedToResolve': 'Failed to resolve item',
    'chat': 'Chat',
    'conversations': 'Conversations',
    'sendMessage': 'Send Message',
    'typeMessage': 'Type a message...',
    'archive': 'Archive',
    'block': 'Block',
    'unblock': 'Unblock',
    'deleteConversation': 'Delete Conversation',
    'areYouSureDelete': 'Are you sure you want to delete this conversation?',
    'conversationDeleted': 'Conversation deleted',
    'failedToDelete': 'Failed to delete conversation',
    'userBlocked': 'User blocked',
    'userUnblocked': 'User unblocked',
    'conversationArchived': 'Conversation archived',
    'profilePicture': 'Profile Picture',
    'takePhoto': 'Take Photo',
    'chooseFromGallery': 'Choose from Gallery',
    'removePhoto': 'Remove Photo',
    'exportData': 'Export Data',
    'deleteAccount': 'Delete Account',
    'areYouSureDeleteAccount':
        'Are you sure you want to delete your account? This action cannot be undone.',
    'accountDeleted': 'Account deleted successfully',
    'dataExported': 'Data exported successfully',
    'profilePictureUpdated': 'Profile picture updated',
    'profilePictureRemoved': 'Profile picture removed',
    'enterEmail': 'Enter your email address',
    'passwordResetSent': 'Password reset email sent',
    'sendSupportMessage': 'Send Support Message',
    'message': 'Message',
    'messageSent': 'Message sent successfully',
    'failedToSendMessage': 'Failed to send message',
    'itemDetails': 'Item Details',
    'distance': 'Distance',
    'calculating': 'Calculating...',
    'locationDisabled': 'Location disabled',
    'permissionDenied': 'Permission denied',
    'permissionDeniedForever': 'Permission denied forever',
    'locationUnavailable': 'Location unavailable',
    'errorCalculating': 'Error calculating',
    'itemDetailsCopied': 'Item details copied to clipboard',
    'failedToShare': 'Failed to share',
    'mapUrlCopied': 'Map URL copied to clipboard',
    'failedToOpenMaps': 'Failed to open maps',
    'locationCoordinatesNotAvailable': 'Location coordinates not available',
    'contactFeatureComingSoon': 'Contact feature coming soon',
    'failedToStartConversation': 'Failed to start conversation',
    'failedToContactOwner': 'Failed to contact owner',
    'noNotifications': 'No notifications',
    'youreAllCaughtUp': 'You\'re all caught up!',
    'markAllRead': 'Mark all read',
    'justNow': 'Just now',
    'minutesAgo': 'minutes ago',
    'hoursAgo': 'hours ago',
    'yesterday': 'Yesterday',
    'daysAgo': 'days ago',
    'reportLostItem': 'Report Lost Item',
    'reportFoundItem': 'Report Found Item',
    'itemType': 'Item Type',
    'selectCategory': 'Select Category',
    'addPhotos': 'Add Photos',
    'itemReported': 'Item reported successfully',
    'failedToReportItem': 'Failed to report item',
    'selectDate': 'Select Date',
    'selectTime': 'Select Time',
    'electronics': 'Electronics',
    'clothing': 'Clothing',
    'accessories': 'Accessories',
    'documents': 'Documents',
    'keys': 'Keys',
    'bags': 'Bags',
    'books': 'Books',
    'toys': 'Toys',
    'sports': 'Sports',
    'other': 'Other',
  };

  static const Map<String, String> _spanishTranslations = {
    'appTitle': 'Perdido y Encontrado',
    'home': 'Inicio',
    'matches': 'Coincidencias',
    'report': 'Reportar',
    'profile': 'Perfil',
    'login': 'Iniciar Sesión',
    'signup': 'Registrarse',
    'logout': 'Cerrar Sesión',
    'email': 'Correo Electrónico',
    'password': 'Contraseña',
    'confirmPassword': 'Confirmar Contraseña',
    'forgotPassword': '¿Olvidaste tu contraseña?',
    'dontHaveAccount': '¿No tienes una cuenta?',
    'alreadyHaveAccount': '¿Ya tienes una cuenta?',
    'lostItem': 'Objeto Perdido',
    'foundItem': 'Objeto Encontrado',
    'title': 'Título',
    'description': 'Descripción',
    'category': 'Categoría',
    'location': 'Ubicación',
    'dateLost': 'Fecha de Pérdida',
    'dateFound': 'Fecha de Encuentro',
    'contactOwner': 'Contactar Propietario',
    'share': 'Compartir',
    'save': 'Guardar',
    'cancel': 'Cancelar',
    'delete': 'Eliminar',
    'edit': 'Editar',
    'search': 'Buscar',
    'filter': 'Filtrar',
    'noItemsFound': 'No se encontraron objetos',
    'beFirstToReport': '¡Sé el primero en reportar un objeto!',
    'noLostItemsYet': 'Aún no hay objetos perdidos',
    'noFoundItemsYet': 'Aún no hay objetos encontrados',
    'loading': 'Cargando...',
    'error': 'Error',
    'retry': 'Reintentar',
    'success': 'Éxito',
    'failed': 'Falló',
    'settings': 'Configuración',
    'language': 'Idioma',
    'notifications': 'Notificaciones',
    'privacy': 'Privacidad',
    'terms': 'Términos',
    'support': 'Soporte',
    'about': 'Acerca de',
    'version': 'Versión',
    'darkMode': 'Modo Oscuro',
    'lightMode': 'Modo Claro',
    'myItems': 'Mis Objetos',
    'active': 'Activo',
    'resolved': 'Resuelto',
    'drafts': 'Borradores',
    'resolve': 'Resolver',
    'markAsResolved': 'Marcar como Resuelto',
    'areYouSureResolve':
        '¿Estás seguro de que quieres marcar este objeto como resuelto?',
    'itemResolved': 'Objeto marcado como resuelto',
    'failedToResolve': 'No se pudo resolver el objeto',
    'chat': 'Chat',
    'conversations': 'Conversaciones',
    'sendMessage': 'Enviar Mensaje',
    'typeMessage': 'Escribe un mensaje...',
    'archive': 'Archivar',
    'block': 'Bloquear',
    'unblock': 'Desbloquear',
    'deleteConversation': 'Eliminar Conversación',
    'areYouSureDelete':
        '¿Estás seguro de que quieres eliminar esta conversación?',
    'conversationDeleted': 'Conversación eliminada',
    'failedToDelete': 'No se pudo eliminar la conversación',
    'userBlocked': 'Usuario bloqueado',
    'userUnblocked': 'Usuario desbloqueado',
    'conversationArchived': 'Conversación archivada',
    'profilePicture': 'Foto de Perfil',
    'takePhoto': 'Tomar Foto',
    'chooseFromGallery': 'Elegir de la Galería',
    'removePhoto': 'Eliminar Foto',
    'exportData': 'Exportar Datos',
    'deleteAccount': 'Eliminar Cuenta',
    'areYouSureDeleteAccount':
        '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer.',
    'accountDeleted': 'Cuenta eliminada exitosamente',
    'dataExported': 'Datos exportados exitosamente',
    'profilePictureUpdated': 'Foto de perfil actualizada',
    'profilePictureRemoved': 'Foto de perfil eliminada',
    'enterEmail': 'Ingresa tu dirección de correo electrónico',
    'passwordResetSent': 'Correo de restablecimiento de contraseña enviado',
    'sendSupportMessage': 'Enviar Mensaje de Soporte',
    'message': 'Mensaje',
    'messageSent': 'Mensaje enviado exitosamente',
    'failedToSendMessage': 'No se pudo enviar el mensaje',
    'itemDetails': 'Detalles del Objeto',
    'distance': 'Distancia',
    'calculating': 'Calculando...',
    'locationDisabled': 'Ubicación deshabilitada',
    'permissionDenied': 'Permiso denegado',
    'permissionDeniedForever': 'Permiso denegado permanentemente',
    'locationUnavailable': 'Ubicación no disponible',
    'errorCalculating': 'Error al calcular',
    'itemDetailsCopied': 'Detalles del objeto copiados al portapapeles',
    'failedToShare': 'No se pudo compartir',
    'mapUrlCopied': 'URL del mapa copiada al portapapeles',
    'failedToOpenMaps': 'No se pudo abrir mapas',
    'locationCoordinatesNotAvailable':
        'Coordenadas de ubicación no disponibles',
    'contactFeatureComingSoon': 'Función de contacto próximamente',
    'failedToStartConversation': 'No se pudo iniciar la conversación',
    'failedToContactOwner': 'No se pudo contactar al propietario',
    'noNotifications': 'Sin notificaciones',
    'youreAllCaughtUp': '¡Estás al día!',
    'markAllRead': 'Marcar todo como leído',
    'justNow': 'Ahora mismo',
    'minutesAgo': 'hace minutos',
    'hoursAgo': 'hace horas',
    'yesterday': 'Ayer',
    'daysAgo': 'hace días',
    'reportLostItem': 'Reportar Objeto Perdido',
    'reportFoundItem': 'Reportar Objeto Encontrado',
    'itemType': 'Tipo de Objeto',
    'selectCategory': 'Seleccionar Categoría',
    'addPhotos': 'Agregar Fotos',
    'itemReported': 'Objeto reportado exitosamente',
    'failedToReportItem': 'No se pudo reportar el objeto',
    'selectDate': 'Seleccionar Fecha',
    'selectTime': 'Seleccionar Hora',
    'electronics': 'Electrónicos',
    'clothing': 'Ropa',
    'accessories': 'Accesorios',
    'documents': 'Documentos',
    'keys': 'Llaves',
    'bags': 'Bolsas',
    'books': 'Libros',
    'toys': 'Juguetes',
    'sports': 'Deportes',
    'other': 'Otro',
  };

  // Placeholder translations for other languages
  static const Map<String, String> _frenchTranslations = _englishTranslations;
  static const Map<String, String> _germanTranslations = _englishTranslations;
  static const Map<String, String> _italianTranslations = _englishTranslations;
  static const Map<String, String> _portugueseTranslations =
      _englishTranslations;
  static const Map<String, String> _russianTranslations = _englishTranslations;
  static const Map<String, String> _chineseTranslations = _englishTranslations;
  static const Map<String, String> _japaneseTranslations = _englishTranslations;
  static const Map<String, String> _koreanTranslations = _englishTranslations;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'zh', 'ja', 'ko']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setLocaleFromLanguageCode(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }
}

final localeProvider = ChangeNotifierProvider<LocaleProvider>((ref) {
  return LocaleProvider();
});

class LocalizationService {
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('es', 'ES'), // Spanish
    Locale('fr', 'FR'), // French
    Locale('de', 'DE'), // German
    Locale('it', 'IT'), // Italian
    Locale('pt', 'PT'), // Portuguese
    Locale('ru', 'RU'), // Russian
    Locale('zh', 'CN'), // Chinese
    Locale('ja', 'JP'), // Japanese
    Locale('ko', 'KR'), // Korean
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'English';
    }
  }

  static String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'ru':
        return '🇷🇺';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      default:
        return '🇺🇸';
    }
  }
}
