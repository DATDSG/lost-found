import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';

/// Language configuration and management
class AppLanguage {
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', name: 'English', shortName: 'En', flag: '🇺🇸'),
    LanguageOption(code: 'si', name: 'සිංහල', shortName: 'Si', flag: '🇱🇰'),
    LanguageOption(code: 'ta', name: 'தமிழ்', shortName: 'Ta', flag: '🇱🇰'),
  ];

  static LanguageOption getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  static int getLanguageIndex(String code) {
    return supportedLanguages.indexWhere((lang) => lang.code == code);
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String shortName;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.shortName,
    required this.flag,
  });
}

/// Language provider for state management
class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  int _currentIndex = 0;

  String get currentLanguage => _currentLanguage;
  int get currentIndex => _currentIndex;
  LanguageOption get currentLanguageOption =>
      AppLanguage.getLanguageByCode(_currentLanguage);

  void setLanguage(String languageCode) {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      _currentIndex = AppLanguage.getLanguageIndex(languageCode);
      notifyListeners();

      // Trigger haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void cycleLanguage() {
    _currentIndex = (_currentIndex + 1) % AppLanguage.supportedLanguages.length;
    _currentLanguage = AppLanguage.supportedLanguages[_currentIndex].code;
    notifyListeners();

    // Trigger haptic feedback
    HapticFeedback.lightImpact();
  }

  void setLanguageByIndex(int index) {
    if (index >= 0 && index < AppLanguage.supportedLanguages.length) {
      _currentIndex = index;
      _currentLanguage = AppLanguage.supportedLanguages[index].code;
      notifyListeners();

      // Trigger haptic feedback
      HapticFeedback.lightImpact();
    }
  }
}

/// Enhanced language button with real-time updates
class LanguageButton extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback? onTap;
  final Function(String)? onLanguageChanged;
  final bool showLanguagePicker;

  const LanguageButton({
    super.key,
    required this.currentLanguage,
    this.onTap,
    this.onLanguageChanged,
    this.showLanguagePicker = true,
  });

  @override
  Widget build(BuildContext context) {
    final languageOption = AppLanguage.getLanguageByCode(currentLanguage);

    return Tooltip(
      message: 'Language: ${languageOption.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showLanguagePicker
              ? () => _showLanguagePicker(context)
              : onTap,
          borderRadius: BorderRadius.circular(DT.r.sm),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DT.r.sm),
              border: Border.all(color: DT.c.brand, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: DT.c.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                languageOption.shortName,
                style: DT.t.body.copyWith(
                  color: DT.c.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LanguagePickerSheet(
        currentLanguage: currentLanguage,
        onLanguageChanged: onLanguageChanged,
      ),
    );
  }
}

/// Language picker bottom sheet
class LanguagePickerSheet extends StatelessWidget {
  final String currentLanguage;
  final Function(String)? onLanguageChanged;

  const LanguagePickerSheet({
    super.key,
    required this.currentLanguage,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DT.r.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: DT.s.sm),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: DT.c.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(DT.s.lg),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.language_rounded, color: DT.c.brand, size: 24),
                    SizedBox(width: DT.s.sm),
                    Text(
                      'Select Language',
                      style: DT.t.title.copyWith(
                        color: DT.c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: DT.c.textMuted),
                    ),
                  ],
                ),

                SizedBox(height: DT.s.lg),

                // Language options
                ...AppLanguage.supportedLanguages.map((language) {
                  final isSelected = language.code == currentLanguage;

                  return Container(
                    margin: EdgeInsets.only(bottom: DT.s.sm),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          // Notify language change through callback
                          if (onLanguageChanged != null) {
                            onLanguageChanged!(language.code);
                          }
                        },
                        borderRadius: BorderRadius.circular(DT.r.md),
                        child: Container(
                          padding: EdgeInsets.all(DT.s.md),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DT.c.brand.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(DT.r.md),
                            border: Border.all(
                              color: isSelected ? DT.c.brand : DT.c.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Flag
                              Text(
                                language.flag,
                                style: const TextStyle(fontSize: 24),
                              ),

                              SizedBox(width: DT.s.md),

                              // Language name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language.name,
                                      style: DT.t.body.copyWith(
                                        color: DT.c.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      language.shortName,
                                      style: DT.t.label.copyWith(
                                        color: DT.c.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection indicator
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: DT.c.brand,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(height: DT.s.lg),

                // Quick cycle button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Cycle to next language
                      if (onLanguageChanged != null) {
                        final currentIndex = AppLanguage.getLanguageIndex(
                          currentLanguage,
                        );
                        final nextIndex =
                            (currentIndex + 1) %
                            AppLanguage.supportedLanguages.length;
                        final nextLanguage =
                            AppLanguage.supportedLanguages[nextIndex];
                        onLanguageChanged!(nextLanguage.code);
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Cycle Language'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DT.c.brand,
                      side: BorderSide(color: DT.c.brand),
                      padding: EdgeInsets.symmetric(vertical: DT.s.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Language indicator widget for showing current language
class LanguageIndicator extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback? onTap;

  const LanguageIndicator({
    super.key,
    required this.currentLanguage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageOption = AppLanguage.getLanguageByCode(currentLanguage);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
        decoration: BoxDecoration(
          color: DT.c.brand.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DT.r.sm),
          border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(languageOption.flag, style: const TextStyle(fontSize: 16)),
            SizedBox(width: DT.s.xs),
            Text(
              languageOption.shortName,
              style: DT.t.label.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
