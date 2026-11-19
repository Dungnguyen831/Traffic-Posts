import 'package:dio/dio.dart';

import '../models/sos_model.dart';
import '../services/api_service.dart';

class SosRepository {
  final ApiService _apiService = ApiService();

  // Dùng chung in-flight request khi nhiều service cùng gọi getActiveSosAlerts() lúc khởi động
  static Future<List<SosResponseDTO>>? _inflightActiveSos;

  // 1. Gọi API POST /sos/alert (Phát tín hiệu)
  Future<SosResponseDTO> createSosAlert({
    required double lat,
    required double lng,
    required String note,
    String? phoneNumber,
  }) async {
    try {
      final payload = <String, dynamic>{
        'latitude': lat,
        'longitude': lng,
        'note': note,
      };
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        payload['phoneNumber'] = phoneNumber.trim();
      }

      final response = await _apiService.dio.post(
        '/sos/alert',
        data: payload,
      );

      final raw = response.data;
      final Map<String, dynamic> jsonMap = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      return SosResponseDTO.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Lỗi khi phát tín hiệu SOS: $e');
    }
  }

  // 2. Gọi API DELETE /sos/{sosId} (Hủy tín hiệu)
  Future<void> cancelSosAlert(String sosId) async {
    try {
      await _apiService.dio.delete('/sos/$sosId');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      // Nếu SOS đã bị xóa/kết thúc trước đó trên server (404/410) thì coi như hủy thành công
      if (statusCode == 404 || statusCode == 410) {
        return;
      }
      throw Exception('Lỗi khi hủy SOS: $e');
    } catch (e) {
      throw Exception('Lỗi khi hủy SOS: $e');
    }
  }

  // 3. Gọi API PATCH /sos/{sosId}/status (Báo đã giải quyết)
  Future<void> resolveSosAlert(String sosId) async {
    try {
      await _apiService.dio.patch(
        '/sos/$sosId/status',
        queryParameters: {'status': 'RESOLVED'},
      );
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái SOS: $e');
    }
  }

  // Lấy danh sách SOS đang tồn tại (tự động gộp các request trùng nhau tại cùng một thời điểm)
  Future<List<SosResponseDTO>> getActiveSosAlerts() {
    if (_inflightActiveSos != null) {
      return _inflightActiveSos!;
    }
    _inflightActiveSos = _fetchActiveSosAlerts().whenComplete(() {
      _inflightActiveSos = null;
    });
    return _inflightActiveSos!;
  }

  Future<List<SosResponseDTO>> _fetchActiveSosAlerts() async {
    try {
      final response = await _apiService.dio.get('/sos/active');
      final raw = response.data;
      final List<dynamic> data = raw is List
          ? raw
          : (raw is Map && raw['data'] is List
                ? raw['data'] as List
                : (raw is Map &&
                          raw['data'] is Map &&
                          (raw['data'] as Map)['content'] is List
                      ? (raw['data'] as Map)['content'] as List
                      : <dynamic>[]));
      return data
          .whereType<Map>()
          .map((json) => SosResponseDTO.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách SOS: $e');
    }
  }
}
