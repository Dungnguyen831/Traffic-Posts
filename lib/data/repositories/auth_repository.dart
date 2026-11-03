import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../services/notification_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/signup_request.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<void> signup(SignupRequest request) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/signup',
        data: request.toJson(),
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'signup_failed'.tr;
      }

      // Save token if available
      if (response.data['data'] != null) {
        final token = response.data['data'] as String;
        _apiService.setToken(token);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map) {
          throw e.response!.data['message'] ?? 'signup_failed'.tr;
        }
        throw 'signup_failed'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final String? deviceToken = await _getDeviceToken();

      final Map<String, dynamic> requestData = request.toJson();

      if (deviceToken != null && deviceToken.isNotEmpty) {
        requestData['deviceToken'] = deviceToken;
      }

      final response = await _apiService.dio.post(
        '/auth/login',
        data: requestData,
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'login_failed'.tr;
      }

      // Parse login response
      final loginResponse = LoginResponse.fromJson(response.data['data']);

      // Save token
      _apiService.setToken(loginResponse.token ?? '');

      return loginResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map) {
          throw e.response!.data['message'] ?? 'login_failed'.tr;
        }
        throw 'login_failed'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String?> _getDeviceToken() async {
    try {
      // Ưu tiên lấy nhanh FCM token đã được NotificationService lấy sẵn khi khởi động
      if (Get.isRegistered<NotificationService>()) {
        final cachedToken = NotificationService.to.fcmToken.value;
        if (cachedToken.isNotEmpty) {
          return cachedToken;
        }
      }

      final String? token = await firebaseMessaging.getToken();
      debugPrint("🔔 FCM Device Token: $token");
      return token;
    } catch (e) {
      debugPrint("❌ Lỗi lấy Device Token: $e");
      return null;
    }
  }
}
