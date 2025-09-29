import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  late final Map<String, dynamic> _map;

  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('si'), Locale('ta')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _L10nDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  Future<void> load() async {
    final code = locale.languageCode;
    try {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      _map = jsonDecode(raw) as Map<String, dynamic>;
    } on FlutterError catch (err) {
      debugPrint('[AppLocalizations] Missing asset for $code: $err');
      _map = const <String, dynamic>{};
    } on FormatException catch (err) {
      debugPrint('[AppLocalizations] Invalid JSON for $code: $err');
      _map = const <String, dynamic>{};
    }
  }

  String t(String key, {Map<String, String> vars = const {}}) {
    var s = (_map[key] ?? key).toString();
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }
}

class _L10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _L10nDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final l10n = AppLocalizations(locale);
    await l10n.load();
    return l10n;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
