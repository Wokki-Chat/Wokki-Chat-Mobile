import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiUrl => dotenv.env['API_URL'] ?? '';
  static String get apiUrlFallback => dotenv.env['API_URL_FALLBACK'] ?? '';
  static String get clientId => dotenv.env['CLIENT_ID'] ?? '';
  static String get hmacSecret => dotenv.env['HMAC_SECRET'] ?? '';

  static bool get allowSelfSigned =>
      dotenv.env['ALLOW_SELF_SIGNED']?.toLowerCase() == 'true';
}