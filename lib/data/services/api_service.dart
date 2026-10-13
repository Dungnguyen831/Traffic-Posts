import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response;

import '../../config/demo_config.dart';
import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';
import 'network_check_interceptor.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  ApiService._internal() {
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Ở chế độ Demo (Web): Mock chặn mọi request ra backend để tránh lỗi CORS và mất kết nối server
    if (DemoConfig.isDemoMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                data: {'success': true, 'data': null, 'message': 'Demo Mode OK'},
                statusCode: 200,
              ),
            );
          },
        ),
      );
    } else {
      // Kiểm tra mạng trước mọi request — tự chờ và retry khi có lại mạng
      _dio.interceptors.add(NetworkCheckInterceptor());
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService.getToken();
          final isAuthEndpoint =
              options.path.contains('/auth/login') ||
              options.path.contains('/auth/register');
          if (token != null && token.isNotEmpty && !isAuthEndpoint) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            if (e.requestOptions.path.contains('/auth/login') ||
                Get.currentRoute == Routes.LOGIN) {
              return handler.next(e);
            }

            // Try to login again
            final credentials = _storageService.getCredentials();
            if (credentials != null) {
              try {
                // Prevent infinite loop if login itself fails
                if (e.requestOptions.path.contains('/auth/login')) {
                  _storageService.removeToken();
                  _storageService.clearCredentials();
                  if (Get.context != null) {
                    Get.offAllNamed(Routes.LOGIN);
                  }
                  return handler.next(e);
                }

                final response = await _dio.post(
                  '/auth/login',
                  data: {
                    'username': credentials['username'],
                    'password': credentials['password'],
                  },
                );

                if (response.data['success'] == true &&
                    response.data['data'] != null) {
                  final newToken = response.data['data'];
                  setToken(newToken);

                  // Retry original request
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';

                  final clonedRequest = await _dio.request(
                    opts.path,
                    options: Options(
                      method: opts.method,
                      headers: opts.headers,
                      contentType: opts.contentType,
                      responseType: opts.responseType,
                    ),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );

                  return handler.resolve(clonedRequest);
                }
              } catch (loginError) {
                // Login failed, proceed to logout
              }
            }

            // Token expired or invalid and auto-login failed
            _storageService.removeToken();
            _storageService.clearCredentials();
            if (Get.context != null) {
              Get.offAllNamed(Routes.LOGIN);
            }
            // Get.snackbar('Phiên đăng nhập hết hạn', 'Vui lòng đăng nhập lại');
          }
          return handler.next(e);
        },
      ),
    );

    // BÊN TRONG HÀM ApiService._internal(), THAY THẾ CHO LOG INTERCEPTOR CŨ

    // ✅ TỐI ƯU LOG INTERCEPTOR: Chỉ in đường link và tính thời gian tải
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Gắn cờ thời gian bắt đầu gọi API
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
          debugPrint('🚀 [API START] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Tính toán thời gian API trả về
          final int startTime = response.requestOptions.extra['startTime'] ?? 0;
          final int endTime = DateTime.now().millisecondsSinceEpoch;
          final int duration = endTime - startTime;
          
          debugPrint('✅ [API DONE] ${response.requestOptions.method} ${response.requestOptions.uri} ⏳ ${duration}ms');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final int startTime = e.requestOptions.extra['startTime'] ?? 0;
          final int endTime = DateTime.now().millisecondsSinceEpoch;
          final int duration = endTime - startTime;
          
          debugPrint('❌ [API ERROR] ${e.requestOptions.method} ${e.requestOptions.uri} ⏳ ${duration}ms');
          return handler.next(e);
        },
      ),
    );
  }

  void setToken(String token) {
    _storageService.setToken(token);
  }

  void clearToken() {
    _storageService.removeToken();
  }

  Dio get dio => _dio;
}
