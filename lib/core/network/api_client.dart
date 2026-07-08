import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final Dio dio;
}
