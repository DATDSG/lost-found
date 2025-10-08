import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';

/// Supported languages
enum SupportedLanguage {
  english('en', 'English', 'En'),
  spanish('es', 'Español', 'Es'),
  french('fr', 'Français', 'Fr');

  final String code;
  final String name;
  final String shortName;

  const SupportedLanguage(this.code, this.name, this.shortName);

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }
}

/// Locale state
class LocaleState {
  final Locale locale;
  final SupportedLanguage language;

  const LocaleState({
    required this.locale,
    required this.language,
  });

  LocaleState copyWith({
    Locale? locale,
    SupportedLanguage? language,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      language: language ?? this.language,
    );
  }
}

/// Locale notifier
class LocaleNotifier extends StateNotifier<LocaleState> {
  final PreferencesService _preferencesService;

  LocaleNotifier(this._preferencesService)
      : super(
          const LocaleState(
            locale: Locale('en'),
            language: SupportedLanguage.english,
          ),
        ) {
    _loadSavedLanguage();
  }

  /// Load saved language from preferences
  Future<void> _loadSavedLanguage() async {
    final savedCode = _preferencesService.getLanguage();
    final language = SupportedLanguage.fromCode(savedCode);
    state = LocaleState(
      locale: Locale(language.code),
      language: language,
    );
  }

  /// Change language
  Future<void> changeLanguage(SupportedLanguage language) async {
    await _preferencesService.setLanguage(language.code);
    state = LocaleState(
      locale: Locale(language.code),
      language: language,
    );
  }

  /// Get localized string
  String translate(String key, [Map<String, String>? params]) {
    // Get translation from current language
    String text = _translations[state.language.code]?[key] ?? key;

    // Replace parameters
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{$key}', value);
      });
    }

    return text;
  }
}

/// Translations map
const Map<String, Map<String, String>> _translations = {
  'en': {
    // App Bar
    'app_name': 'LOST FINDER',

    // Bottom Navigation
    'nav_home': 'Home',
    'nav_matches': 'Matches',
    'nav_report': 'Report',
    'nav_profile': 'Profile',

    // Home Screen
    'search_hint': 'Search lost or found items...',
    'filter': 'Filter',
    'no_items': 'No items found',
    'no_items_desc': 'Try adjusting your search or filters',

    // Filter
    'filters': 'Filters',
    'lost': 'Lost',
    'found': 'Found',
    'time': 'Time',
    'distance': 'Distance',
    'category': 'Category',
    'location': 'Location',
    'clear': 'Clear',
    'apply': 'Apply',
    'all_time': 'All time',
    'last_24h': 'Last 24 hours',
    'last_week': 'Last week',
    'last_month': 'Last month',
    'any_distance': 'Any distance',
    'nearby': 'Nearby (< 1 mi)',
    'within_5mi': 'Within 5 mi',
    'within_10mi': 'Within 10 mi',
    'within_25mi': 'Within 25 mi',
    'all_categories': 'All categories',

    // Categories
    'electronics': 'Electronics',
    'clothing': 'Clothing',
    'accessories': 'Accessories',
    'documents': 'Documents',
    'keys': 'Keys',
    'bags': 'Bags',
    'pets': 'Pets',
    'other': 'Other',

    // Item Card
    'contact': 'Contact',
    'view_details': 'View Details',

    // Item Details
    'item_details': 'Item Details',
    'description': 'Description',
    'no_description': 'No description provided',
    'date': 'Date',
    'time_label': 'Time',
    'contact_owner': 'Contact Owner',
    'share': 'Share',
    'starting_conversation': 'Starting conversation...',
    'failed_to_start_conversation': 'Failed to start conversation',

    // Notifications
    'notifications': 'Notifications',
    'mark_all_read': 'Mark all read',
    'no_notifications': 'No notifications',
    'all_caught_up': 'You\'re all caught up!',
    'just_now': 'Just now',

    // Chat
    'chat': 'Chat',
    'no_conversations': 'No conversations',
    'start_chatting': 'Start chatting by contacting item owners',
    'type_message': 'Type a message...',
    'send': 'Send',

    // Matches
    'matches': 'Matches',
    'no_matches': 'No matches found',
    'no_matches_desc': 'We\'ll notify you when we find potential matches',

    // Profile
    'profile': 'Profile',
    'my_items': 'My Items',
    'active': 'Active',
    'resolved': 'Resolved',
    'drafts': 'Drafts',
    'settings': 'Settings',
    'logout': 'Logout',

    // Common
    'error': 'Error',
    'retry': 'Retry',
    'loading': 'Loading...',
    'cancel': 'Cancel',
    'ok': 'OK',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
  },
  'es': {
    // App Bar
    'app_name': 'BUSCADOR PERDIDOS',

    // Bottom Navigation
    'nav_home': 'Inicio',
    'nav_matches': 'Coincidencias',
    'nav_report': 'Reportar',
    'nav_profile': 'Perfil',

    // Home Screen
    'search_hint': 'Buscar objetos perdidos o encontrados...',
    'filter': 'Filtrar',
    'no_items': 'No se encontraron artículos',
    'no_items_desc': 'Intenta ajustar tu búsqueda o filtros',

    // Filter
    'filters': 'Filtros',
    'lost': 'Perdido',
    'found': 'Encontrado',
    'time': 'Tiempo',
    'distance': 'Distancia',
    'category': 'Categoría',
    'location': 'Ubicación',
    'clear': 'Limpiar',
    'apply': 'Aplicar',
    'all_time': 'Todo el tiempo',
    'last_24h': 'Últimas 24 horas',
    'last_week': 'Última semana',
    'last_month': 'Último mes',
    'any_distance': 'Cualquier distancia',
    'nearby': 'Cerca (< 1 mi)',
    'within_5mi': 'Dentro de 5 mi',
    'within_10mi': 'Dentro de 10 mi',
    'within_25mi': 'Dentro de 25 mi',
    'all_categories': 'Todas las categorías',

    // Categories
    'electronics': 'Electrónica',
    'clothing': 'Ropa',
    'accessories': 'Accesorios',
    'documents': 'Documentos',
    'keys': 'Llaves',
    'bags': 'Bolsas',
    'pets': 'Mascotas',
    'other': 'Otro',

    // Item Card
    'contact': 'Contactar',
    'view_details': 'Ver Detalles',

    // Item Details
    'item_details': 'Detalles del Artículo',
    'description': 'Descripción',
    'no_description': 'No hay descripción disponible',
    'date': 'Fecha',
    'time_label': 'Hora',
    'contact_owner': 'Contactar Propietario',
    'share': 'Compartir',
    'starting_conversation': 'Iniciando conversación...',
    'failed_to_start_conversation': 'Error al iniciar conversación',

    // Notifications
    'notifications': 'Notificaciones',
    'mark_all_read': 'Marcar todo como leído',
    'no_notifications': 'No hay notificaciones',
    'all_caught_up': '¡Estás al día!',
    'just_now': 'Justo ahora',

    // Chat
    'chat': 'Chat',
    'no_conversations': 'No hay conversaciones',
    'start_chatting': 'Comienza a chatear contactando a los propietarios',
    'type_message': 'Escribe un mensaje...',
    'send': 'Enviar',

    // Matches
    'matches': 'Coincidencias',
    'no_matches': 'No se encontraron coincidencias',
    'no_matches_desc': 'Te notificaremos cuando encontremos coincidencias',

    // Profile
    'profile': 'Perfil',
    'my_items': 'Mis Artículos',
    'active': 'Activo',
    'resolved': 'Resuelto',
    'drafts': 'Borradores',
    'settings': 'Configuración',
    'logout': 'Cerrar Sesión',

    // Common
    'error': 'Error',
    'retry': 'Reintentar',
    'loading': 'Cargando...',
    'cancel': 'Cancelar',
    'ok': 'OK',
    'save': 'Guardar',
    'delete': 'Eliminar',
    'edit': 'Editar',
  },
  'fr': {
    // App Bar
    'app_name': 'CHERCHEUR PERDU',

    // Bottom Navigation
    'nav_home': 'Accueil',
    'nav_matches': 'Correspondances',
    'nav_report': 'Signaler',
    'nav_profile': 'Profil',

    // Home Screen
    'search_hint': 'Rechercher des objets perdus ou trouvés...',
    'filter': 'Filtrer',
    'no_items': 'Aucun article trouvé',
    'no_items_desc': 'Essayez d\'ajuster votre recherche ou vos filtres',

    // Filter
    'filters': 'Filtres',
    'lost': 'Perdu',
    'found': 'Trouvé',
    'time': 'Temps',
    'distance': 'Distance',
    'category': 'Catégorie',
    'location': 'Emplacement',
    'clear': 'Effacer',
    'apply': 'Appliquer',
    'all_time': 'Tout le temps',
    'last_24h': 'Dernières 24 heures',
    'last_week': 'Dernière semaine',
    'last_month': 'Dernier mois',
    'any_distance': 'Toute distance',
    'nearby': 'À proximité (< 1 mi)',
    'within_5mi': 'Dans un rayon de 5 mi',
    'within_10mi': 'Dans un rayon de 10 mi',
    'within_25mi': 'Dans un rayon de 25 mi',
    'all_categories': 'Toutes les catégories',

    // Categories
    'electronics': 'Électronique',
    'clothing': 'Vêtements',
    'accessories': 'Accessoires',
    'documents': 'Documents',
    'keys': 'Clés',
    'bags': 'Sacs',
    'pets': 'Animaux',
    'other': 'Autre',

    // Item Card
    'contact': 'Contacter',
    'view_details': 'Voir les Détails',

    // Item Details
    'item_details': 'Détails de l\'Article',
    'description': 'Description',
    'no_description': 'Aucune description fournie',
    'date': 'Date',
    'time_label': 'Heure',
    'contact_owner': 'Contacter le Propriétaire',
    'share': 'Partager',
    'starting_conversation': 'Démarrage de la conversation...',
    'failed_to_start_conversation': 'Échec du démarrage de la conversation',

    // Notifications
    'notifications': 'Notifications',
    'mark_all_read': 'Tout marquer comme lu',
    'no_notifications': 'Aucune notification',
    'all_caught_up': 'Vous êtes à jour!',
    'just_now': 'À l\'instant',

    // Chat
    'chat': 'Chat',
    'no_conversations': 'Aucune conversation',
    'start_chatting': 'Commencez à discuter en contactant les propriétaires',
    'type_message': 'Tapez un message...',
    'send': 'Envoyer',

    // Matches
    'matches': 'Correspondances',
    'no_matches': 'Aucune correspondance trouvée',
    'no_matches_desc':
        'Nous vous avertirons lorsque nous trouverons des correspondances',

    // Profile
    'profile': 'Profil',
    'my_items': 'Mes Articles',
    'active': 'Actif',
    'resolved': 'Résolu',
    'drafts': 'Brouillons',
    'settings': 'Paramètres',
    'logout': 'Déconnexion',

    // Common
    'error': 'Erreur',
    'retry': 'Réessayer',
    'loading': 'Chargement...',
    'cancel': 'Annuler',
    'ok': 'OK',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'edit': 'Modifier',
  },
};

/// Provider for preferences service
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Provider for locale
final localeProvider =
    StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  final prefsService = ref.read(preferencesServiceProvider);
  return LocaleNotifier(prefsService);
});
