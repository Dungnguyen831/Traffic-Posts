import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../config/demo_config.dart';
import '../models/location_model.dart';
import '../models/traffic_post_model.dart';
import '../services/api_service.dart';

class TrafficPostRepository {
  final ApiService _apiService = ApiService();
  static final List<TrafficPostModel> _demoPosts = DemoConfig.getInitialSamplePosts();

  static void addDemoPost(TrafficPostModel post) {
    if (!_demoPosts.any((p) => p.id == post.id)) {
      _demoPosts.insert(0, post);
    }
  }

  Future<List<TrafficPostModel>> getPosts({
    required String location,
    int page = 0,
    int size = 10,
    String? keyword,
  }) async {
    if (DemoConfig.isDemoMode) {
      final all = <TrafficPostModel>[..._demoPosts];
      if (keyword != null && keyword.isNotEmpty) {
        final kw = keyword.toLowerCase();
        return all.where((p) {
          final contentMatch = p.content?.toLowerCase().contains(kw) ?? false;
          final tagMatch = p.hashtags?.any((t) => t.toLowerCase().contains(kw)) ?? false;
          final addrMatch =
              p.location?.address.toLowerCase().contains(kw) ?? false;
          return contentMatch || tagMatch || addrMatch;
        }).toList();
      }
      return all;
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
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
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response!.data is Map
            ? e.response!.data['message'] ?? 'Không thể tải bài viết'
            : 'Không thể tải bài viết';
        throw errorMessage;
      }
      throw 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
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
    String status = 'ACTIVE',
    String? filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if (DemoConfig.isDemoMode) {
      final newPost = TrafficPostModel(
        id: 'post_demo_${DateTime.now().millisecondsSinceEpoch}',
        userId: '1',
        userName: 'Demo User (Web)',
        content: content,
        type: type,
        hashtags: hashtags,
        location: LocationModel(lat: lat, lng: lng, address: address),
        status: status,
        likes: 0,
        isLiked: false,
        timestamp: DateTime.now(),
      );
      _demoPosts.insert(0, newPost);
      return newPost;
    }

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
        final fileName = filePath.split('/').last;
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
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'Không thể tạo bài viết';
      }

      final postData = response.data['data'] ?? response.data;
      return TrafficPostModel.fromJson(postData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tạo bài viết';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Cập nhật bài viết
  Future<void> updatePost({
    required String postId,
    required String userId,
    required String type,
    required String content,
    required double lat,
    required double lng,
    required String address,
    required String status,
  }) async {
    try {
      final response = await _apiService.dio.put(
        '/TrafficPost/$postId',
        data: {
          'userId': userId,
          'type': type,
          'content': content,
          'location': {'lat': lat, 'lng': lng, 'address': address},
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'Không thể cập nhật bài viết';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể cập nhật bài viết';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Báo cáo bài viết
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    if (DemoConfig.isDemoMode) return;
    try {
      await _apiService.dio.post(
        '/PostReport/$postId/report',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể báo cáo bài viết';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Like / Unlike bài viết (toggle - cùng 1 endpoint)
  Future<void> likePost(String postId) async {
    if (DemoConfig.isDemoMode) return;
    try {
      await _apiService.dio.post('/TrafficPost/$postId/like');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể thực hiện hành động';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Xóa bài viết
  Future<void> deletePost(String postId) async {
    if (DemoConfig.isDemoMode) {
      _demoPosts.removeWhere((p) => p.id == postId);
      return;
    }
    try {
      final response = await _apiService.dio.delete('/TrafficPost/$postId');

      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'Không thể xóa bài viết';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể xóa bài viết';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }
}
