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
    final results = await Future.wait([
      rootBundle.loadString('assets/json/locales/en_US.json'),
      rootBundle.loadString('assets/json/locales/vi_VN.json'),
    ]);

    _keys = {
      'en_US': Map<String, String>.from(json.decode(results[0])),
      'vi_VN': Map<String, String>.from(json.decode(results[1])),
    };
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
