import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../config/demo_config.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/signup_request.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<void> signup(SignupRequest request) async {
    if (DemoConfig.isDemoMode) {
      _apiService.setToken('demo_token');
      return;
    }
    try {
      final response = await _apiService.dio.post(
        '/auth/signup',
        data: request.toJson(),
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'Đăng ký thất bại';
      }

      // Save token if available
      if (response.data['data'] != null) {
        final token = response.data['data'] as String;
        _apiService.setToken(token);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map) {
          throw e.response!.data['message'] ?? 'Đăng ký thất bại';
        }
        throw 'Đăng ký thất bại';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    if (DemoConfig.isDemoMode) {
      const demoToken = 'demo_token_web';
      _apiService.setToken(demoToken);
      return LoginResponse(
        id: 1,
        username: request.username.isNotEmpty ? request.username : 'demouser',
        fullname: 'Nguyễn Anh Dũng',
        province: 'Hà Nội',
        relativePhone: '0988888888',
        phoneNumber: '0983168888',
        token: demoToken,
      );
    }
    try {
      String? deviceToken = kIsWeb ? null : await _getDeviceToken(); 
      
      final Map<String, dynamic> requestData = request.toJson();
      
      if (deviceToken != null) {
        requestData['deviceToken'] = deviceToken;
      }

      final response = await _apiService.dio.post(
        '/auth/login',
        data: requestData, 
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'Đăng nhập thất bại';
      }

      // Parse login response
      final loginResponse = LoginResponse.fromJson(response.data['data']);

      // Save token
      _apiService.setToken(loginResponse.token ?? '');

      return loginResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map) {
          throw e.response!.data['message'] ?? 'Đăng nhập thất bại';
        }
        throw 'Đăng nhập thất bại';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String?> _getDeviceToken() async {
    if (kIsWeb) return null;
    try {
      // Xin quyền (Quan trọng cho iOS)
      await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      String? token = await firebaseMessaging.getToken();
      return token;
    } catch (e) {
      return null; 
    }
  }
}
