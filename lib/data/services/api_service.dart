import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../modules/emergency/controllers/emergency_controller.dart';
import '../../modules/login/controllers/login_controller.dart';
import '../../modules/map/controllers/map_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/profile/controllers/user_profile_controller.dart';
import '../../routes/app_pages.dart';
import '../../services/storage_service.dart';
import 'network_check_interceptor.dart';
import 'sos_stream_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  /// Khóa đồng bộ khi nhiều request cùng gặp 401 để chỉ gọi /auth/login 1 lần
  Future<String?>? _refreshingTokenFuture;

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

    // Kiểm tra mạng trước mọi request — tự chờ và retry khi có lại mạng
    _dio.interceptors.add(NetworkCheckInterceptor());

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService.getToken();
          final isAuthEndpoint =
              options.path.contains('/auth/login') ||
              options.path.contains('/auth/register') ||
              options.path.contains('/auth/signup');
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

            // Try to refresh token using stored credentials (deduplicated across concurrent 401s)
            final newToken = await _refreshTokenIfPossible();
            if (newToken != null && newToken.isNotEmpty) {
              try {
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
              } catch (_) {
                // Nếu retry vẫn lỗi thì chuyển xuống xử lý đăng xuất
              }
            }

            // Token expired or invalid and auto-login failed
            await _storageService.removeToken();
            await _storageService.clearCredentials();
            await _storageService.clearUserInfo();
            UserProfileController.clearCache();

            if (Get.isRegistered<EmergencyController>()) {
              Get.find<EmergencyController>().resetSosState();
              Get.delete<EmergencyController>(force: true);
            }
            if (Get.isRegistered<SosStreamService>()) {
              final sosStream = Get.find<SosStreamService>();
              sosStream.disconnect();
              sosStream.sosList.clear();
              Get.delete<SosStreamService>(force: true);
            }
            if (Get.isRegistered<MapController>()) {
              Get.delete<MapController>(force: true);
            }
            if (Get.isRegistered<LoginController>()) {
              Get.delete<LoginController>(force: true);
            }
            if (Get.isRegistered<ProfileController>()) {
              Get.delete<ProfileController>(force: true);
            }
            if (Get.context != null) {
              Get.offAllNamed(Routes.LOGIN);
            }
          }
          return handler.next(e);
        },
      ),
    );

    // TỐI ƯU LOG INTERCEPTOR: Chỉ in đường link và tính thời gian tải ở chế độ debug
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
            debugPrint('🚀 [API START] ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            final int startTime =
                response.requestOptions.extra['startTime'] ?? 0;
            final int endTime = DateTime.now().millisecondsSinceEpoch;
            final int duration = endTime - startTime;

            debugPrint(
              '✅ [API DONE] ${response.requestOptions.method} ${response.requestOptions.uri} ⏳ ${duration}ms',
            );
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            final int startTime = e.requestOptions.extra['startTime'] ?? 0;
            final int endTime = DateTime.now().millisecondsSinceEpoch;
            final int duration = endTime - startTime;

            debugPrint(
              '❌ [API ERROR] ${e.requestOptions.method} ${e.requestOptions.uri} ⏳ ${duration}ms',
            );
            return handler.next(e);
          },
        ),
      );
    }
  }

  Future<String?> _refreshTokenIfPossible() {
    if (_refreshingTokenFuture != null) {
      return _refreshingTokenFuture!;
    }
    final completer = Completer<String?>();
    _refreshingTokenFuture = completer.future;

    () async {
      try {
        final credentials = _storageService.getCredentials();
        if (credentials == null) {
          completer.complete(null);
          return;
        }

        final response = await _dio.post(
          '/auth/login',
          data: {
            'username': credentials['username'],
            'password': credentials['password'],
          },
        );

        if (response.data is Map &&
            response.data['success'] == true &&
            response.data['data'] != null) {
          final data = response.data['data'];
          final String? newToken = data is String
              ? data
              : (data is Map ? data['token'] as String? : null);
          if (newToken != null && newToken.isNotEmpty) {
            setToken(newToken);
            completer.complete(newToken);
            return;
          }
        }
        completer.complete(null);
      } catch (_) {
        completer.complete(null);
      } finally {
        _refreshingTokenFuture = null;
      }
    }();

    return completer.future;
  }

  void setToken(String token) {
    _storageService.setToken(token);
  }

  void clearToken() {
    _storageService.removeToken();
  }

  Dio get dio => _dio;
}
