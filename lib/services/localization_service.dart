import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  static const locale = Locale('vi', 'VN');
  static const fallbackLocale = Locale('en', 'US');

  static final langs = ['Tiếng Việt', 'English'];

  static final locales = [const Locale('vi', 'VN'), const Locale('en', 'US')];

  static Map<String, Map<String, String>> _keys = {};

  @override
  Map<String, Map<String, String>> get keys => _keys;

  static Future<void> init() async {
    try {
      final en = await rootBundle.loadString('assets/json/locales/en_US.json');
      final vi = await rootBundle.loadString('assets/json/locales/vi_VN.json');

      _keys = {
        'en_US': Map<String, String>.from(json.decode(en)),
        'vi_VN': Map<String, String>.from(json.decode(vi)),
      };
    } catch (e) {
      debugPrint('LocalizationService init warning: $e');
      _keys = {
        'en_US': {},
        'vi_VN': {},
      };
    }
  }

  static void changeLocale(String lang) {
    final locale = _getLocaleFromLanguage(lang);
    Get.updateLocale(locale);
  }

  static Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale!;
  }
}
