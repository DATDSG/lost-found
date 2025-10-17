import 'package:flutter/material.dart';

/// Localized text strings for different languages
class AppLocalizations {
  static const Map<String, Map<String, String>> _localizations = {
    'en': {
      // App Bar
      'app_name': 'Lost Finder',
      'app_tagline': 'Find & Return',
      'chat_tooltip': 'Chat',
      'notifications_tooltip': 'Notifications',
      'language_tooltip': 'Language',

      // Navigation
      'home': 'Home',
      'report': 'Report',
      'matches': 'Matches',
      'profile': 'Profile',

      // Common Actions
      'quick_report': 'Quick Report',
      'lost_item': 'Lost Item',
      'found_item': 'Found Item',
      'mark_all_read': 'Mark all read',
      'select_language': 'Select Language',
      'cycle_language': 'Cycle Language',

      // Notifications
      'notifications': 'Notifications',
      'new_match_found': 'New match found for your lost wallet',
      'someone_found_keys': 'Someone found your keys',
      'message_from_john': 'Message from John about your bag',
      'minutes_ago': 'minutes ago',

      // Profile
      'settings': 'Settings',
      'logout': 'Logout',
      'edit_profile': 'Edit Profile',

      // General
      'find_what_matters': 'Find what matters',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
    },
    'si': {
      // App Bar
      'app_name': 'නැතිවූ දේ සොයන්න',
      'app_tagline': 'සොයා ගෙන ආපසු දෙන්න',
      'chat_tooltip': 'කතාබස්',
      'notifications_tooltip': 'දැනුම්දීම්',
      'language_tooltip': 'භාෂාව',

      // Navigation
      'home': 'මුල් පිටුව',
      'report': 'වාර්තාව',
      'matches': 'ගැලපීම්',
      'profile': 'පැතිකඩ',

      // Common Actions
      'quick_report': 'ක්‍රියාකාරී වාර්තාව',
      'lost_item': 'නැතිවූ දේ',
      'found_item': 'සොයාගත් දේ',
      'mark_all_read': 'සියල්ල කියවූ ලෙස සලකුණු කරන්න',
      'select_language': 'භාෂාව තෝරන්න',
      'cycle_language': 'භාෂාව වෙනස් කරන්න',

      // Notifications
      'notifications': 'දැනුම්දීම්',
      'new_match_found': 'ඔබේ නැතිවූ පසුම්බිය සඳහා නව ගැලපීමක් හමුවිය',
      'someone_found_keys': 'කෙනෙකු ඔබේ යතුරු සොයාගත්තේය',
      'message_from_john': 'ජෝන්ගෙන් ඔබේ බෑගය ගැන පණිවිඩය',
      'minutes_ago': 'මිනිත්තු කිහිපයකට පෙර',

      // Profile
      'settings': 'සැකසුම්',
      'logout': 'පිටවීම',
      'edit_profile': 'පැතිකඩ සංස්කරණය',

      // General
      'find_what_matters': 'වැදගත් දේ සොයන්න',
      'loading': 'පූරණය වෙමින්...',
      'error': 'දෝෂය',
      'success': 'සාර්ථකය',
      'cancel': 'අවලංගු කරන්න',
      'save': 'සුරකින්න',
      'delete': 'මකන්න',
      'edit': 'සංස්කරණය',
      'close': 'වසන්න',
    },
    'ta': {
      // App Bar
      'app_name': 'இழந்தவை கண்டுபிடி',
      'app_tagline': 'கண்டுபிடித்து திருப்பி கொடு',
      'chat_tooltip': 'உரையாடல்',
      'notifications_tooltip': 'அறிவிப்புகள்',
      'language_tooltip': 'மொழி',

      // Navigation
      'home': 'முகப்பு',
      'report': 'அறிக்கை',
      'matches': 'பொருத்தங்கள்',
      'profile': 'சுயவிவரம்',

      // Common Actions
      'quick_report': 'விரைவு அறிக்கை',
      'lost_item': 'இழந்த பொருள்',
      'found_item': 'கண்டுபிடிக்கப்பட்ட பொருள்',
      'mark_all_read': 'அனைத்தையும் படித்ததாக குறிக்கவும்',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'cycle_language': 'மொழியை மாற்றவும்',

      // Notifications
      'notifications': 'அறிவிப்புகள்',
      'new_match_found': 'உங்கள் இழந்த பணப்பையுக்கு புதிய பொருத்தம் கிடைத்தது',
      'someone_found_keys': 'யாரோ உங்கள் சாவிகளை கண்டுபிடித்தனர்',
      'message_from_john': 'ஜானிடமிருந்து உங்கள் பையைப் பற்றிய செய்தி',
      'minutes_ago': 'நிமிடங்களுக்கு முன்பு',

      // Profile
      'settings': 'அமைப்புகள்',
      'logout': 'வெளியேறு',
      'edit_profile': 'சுயவிவரத்தைத் திருத்தவும்',

      // General
      'find_what_matters': 'முக்கியமானதைக் கண்டுபிடி',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'delete': 'நீக்கு',
      'edit': 'திருத்து',
      'close': 'மூடு',
    },
  };

  static String getText(String key, String language) {
    return _localizations[language]?[key] ?? _localizations['en']![key]!;
  }

  static Map<String, String> getLanguageStrings(String language) {
    return _localizations[language] ?? _localizations['en']!;
  }
}

/// Language-aware text widget that updates in real-time
class LocalizedText extends StatelessWidget {
  final String textKey;
  final String? language;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText(
    this.textKey, {
    super.key,
    this.language,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // Get current language from context or use provided language
    final currentLanguage = language ?? 'en';
    final text = AppLocalizations.getText(textKey, currentLanguage);

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Language-aware button widget
class LocalizedButton extends StatelessWidget {
  final String textKey;
  final String? language;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;

  const LocalizedButton(
    this.textKey, {
    super.key,
    this.language,
    this.onPressed,
    this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguage = language ?? 'en';
    final text = AppLocalizations.getText(textKey, currentLanguage);

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(text),
    );
  }
}

/// Language-aware app bar title
class LocalizedAppBarTitle extends StatelessWidget {
  final String textKey;
  final String? language;

  const LocalizedAppBarTitle(this.textKey, {super.key, this.language});

  @override
  Widget build(BuildContext context) {
    final currentLanguage = language ?? 'en';
    final text = AppLocalizations.getText(textKey, currentLanguage);

    return Text(text);
  }
}

/// Language context extension for easy access
extension LanguageContext on BuildContext {
  String get currentLanguage => 'en'; // This would be provided by a provider

  String localizedText(String key) {
    return AppLocalizations.getText(key, currentLanguage);
  }
}
