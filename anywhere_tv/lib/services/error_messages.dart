import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ErrorMessages {
  static Map<String, String>? _messages;

  static Future<void> init() async {
    try {
      final raw = await rootBundle.loadString('error_message_ko.json');
      _messages = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      _messages = {};
    }
  }

  static String get(String code, {String fallback = '오류가 발생했습니다.'}) {
    return _messages?[code] ?? fallback;
  }
}