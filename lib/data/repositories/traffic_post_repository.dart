import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

import '../models/traffic_post_model.dart';
import '../services/api_service.dart';

class TrafficPostRepository {
  final ApiService _apiService = ApiService();
  static final Dio _aiDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Kiểm duyệt ảnh bằng AI (POST /predict)
  /// Trả về true nếu label == 1 (ảnh giao thông hợp lệ), false nếu label == 0
  Future<bool> verifyTrafficImage(
    String filePath, {
    CancelToken? cancelToken,
  }) async {
    final rawUrl = dotenv.env['AI_PREDICT_URL']?.trim();
    final predictUrl = (rawUrl != null && rawUrl.isNotEmpty)
        ? rawUrl
        : 'http://103.249.117.232:46016/predict';

    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _aiDio.post(
      predictUrl,
      data: formData,
      cancelToken: cancelToken,
    );

    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;

    if (data is Map) {
      final label = data['label'];
      return label == 1 || label == '1' || label == true;
    }

    return false;
  }

  Future<List<TrafficPostModel>> getPosts({
    String location = '',
    int page = 0,
    int size = 10,
    String? keyword,
    String? hashtag,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (hashtag != null && hashtag.isNotEmpty) {
        queryParams['hashtag'] = hashtag;
      }
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }
      if (radiusKm != null) {
        queryParams['radius'] = radiusKm;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }
      final response = await _apiService.dio.get(
        '/TrafficPost',
        queryParameters: queryParams,
      );
      // Check response structure
      if (response.data == null) {
        return [];
      }

      // Handle different response formats
      List<dynamic> postsJson = [];

      if (response.data is Map) {
        // New format: { data: { content: [...] }, success: true }
        final data = response.data['data'];
        if (data != null) {
          if (data is Map && data['content'] != null) {
            postsJson = data['content'] as List;
          } else if (data is List) {
            postsJson = data;
          }
        } else if (response.data['content'] != null) {
          // Fallback for direct Pageable response
          postsJson = response.data['content'] as List;
        }
      } else if (response.data is List) {
        postsJson = response.data as List;
      }

      return postsJson
          .map(
            (json) => TrafficPostModel.fromJson(json as Map<String, dynamic>),
          )
          .where((post) => post.isVisible)
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response!.data is Map
            ? e.response!.data['message'] ?? 'post_load_error'.tr
            : 'post_load_error'.tr;
        throw errorMessage;
      }
      throw 'network_error_retry'.tr;
    } catch (e) {
      throw 'Có lỗi xảy ra: ${e.toString()}';
    }
  }

  /// Tạo bài viết mới với upload progress callback
  Future<TrafficPostModel> createPost({
    required String type,
    required String content,
    required double lat,
    required double lng,
    required String address,
    List<String> hashtags = const [],
    String status = 'NORMAL',
    String? filePath,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Tạo JSON object cho TrafficPost
      final trafficPostJson = {
        'type': type,
        'content': content,
        'location': {'lat': lat, 'lng': lng, 'address': address},
        'hashtags': hashtags,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Convert to JSON string
      final trafficPostString = jsonEncode(trafficPostJson);

      // Tạo FormData với Content-Type đúng theo API spec
      final formData = FormData();

      // Add TrafficPost as multipart với contentType = application/json
      formData.files.add(
        MapEntry(
          'TrafficPost',
          MultipartFile.fromString(
            trafficPostString,
            contentType: MediaType('application', 'json'),
          ),
        ),
      );

      // Add file if provided
      if (filePath != null && filePath.isNotEmpty) {
        final fileName = filePath.split(RegExp(r'[/\\]')).last;
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(filePath, filename: fileName),
          ),
        );
      }

      final response = await _apiService.dio.post(
        '/TrafficPost',
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'post_create_error'.tr;
      }

      final postData = response.data['data'] ?? response.data;
      return TrafficPostModel.fromJson(postData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw 'post_upload_cancelled'.tr;
      }
      if (e.response?.statusCode == 403) {
        if (e.response?.data is Map && e.response!.data['message'] != null) {
          throw e.response!.data['message'].toString();
        }
        throw 'reputation_cannot_post_alert'.tr;
      }
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'post_create_error'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Cập nhật bài viết (giữ nguyên thời gian và các trường khác, chỉ cập nhật nội dung)
  Future<void> updatePost({
    required String postId,
    required String type,
    required String content,
    required double lat,
    required double lng,
    required String address,
    required List<String> hashtags,
    required String status,
    required DateTime timestamp,
  }) async {
    try {
      final response = await _apiService.dio.put(
        '/TrafficPost/$postId',
        data: {
          'type': type,
          'content': content,
          'location': {'lat': lat, 'lng': lng, 'address': address},
          'hashtags': hashtags,
          'status': status,
          'timestamp': timestamp.toUtc().toIso8601String(),
        },
      );

      if (response.data is Map && response.data['success'] == false) {
        throw response.data['message'] ?? 'post_update_error'.tr;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'post_update_error'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Báo cáo bài viết
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      await _apiService.dio.post(
        '/PostReport/$postId/report',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'post_report_error'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Like / Unlike bài viết (toggle - cùng 1 endpoint)
  Future<void> likePost(String postId) async {
    try {
      await _apiService.dio.post('/TrafficPost/$postId/like');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'action_failed'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Xóa bài viết
  Future<void> deletePost(String postId) async {
    try {
      final response = await _apiService.dio.delete('/TrafficPost/$postId');

      if (response.data is Map && response.data['success'] == false) {
        throw response.data['message'] ?? 'post_delete_error'.tr;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'post_delete_error'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }
}
