// lib/common/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = dotenv.env['API_BASE_URL'] ??
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.example.com',
    );
