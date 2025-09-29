import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LangController extends ChangeNotifier {
  static const _k = 'app_lang';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_k);
    if (code != null) _locale = Locale(code);
  }

  Future<void> setLocale(Locale l) async {
    _locale = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k, l.languageCode);
    notifyListeners();
  }

  Future<void> cycle() async {
    final order = ['en', 'si', 'ta'];
    final i = order.indexOf(_locale.languageCode);
    final next = order[(i + 1) % order.length];
    await setLocale(Locale(next));
  }
}
