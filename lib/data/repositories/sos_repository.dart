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
      final response = await _apiService.dio.post(
        '/sos/alert',
        data: {
          'latitude': lat,
          'longitude': lng,
          'note': note,
          'phoneNumber': phoneNumber,
        },
      );
      return SosResponseDTO.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi khi phát tín hiệu SOS: $e');
    }
  }

  // 2. Gọi API DELETE /sos/{sosId} (Hủy tín hiệu)
  Future<void> cancelSosAlert(String sosId) async {
    try {
      await _apiService.dio.delete('/sos/$sosId');
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
      final List data = response.data as List;
      return data
          .map((json) => SosResponseDTO.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách SOS: $e');
    }
  }
}
