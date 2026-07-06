import 'package:dio/dio.dart';

/// Backend base URL, reused as-is from the RN app (lib/constants.ts).
/// Override at build time with --dart-define=API_BASE=https://...
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://dangmatch.vercel.app',
);

class ApiClient {
  ApiClient._internal()
    : dio = Dio(
        BaseOptions(
          baseUrl: kApiBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  static final ApiClient instance = ApiClient._internal();

  final Dio dio;
}
