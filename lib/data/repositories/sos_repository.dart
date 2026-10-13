import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import '../../config/demo_config.dart';
import '../../services/storage_service.dart';
import '../models/sos_model.dart';
import '../services/sos_stream_service.dart';

class SosRepository {
  final Dio _dio = Dio();
  final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  // Cấu hình Header chứa Token
  Options get _options {
    final token = StorageService.to.getToken();
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // 1. Gọi API POST /sos/alert (Phát tín hiệu)
  Future<SosResponseDTO> createSosAlert({
    required double lat,
    required double lng,
    required String note,
    String? phoneNumber,
  }) async {
    if (DemoConfig.isDemoMode) {
      final newSos = SosResponseDTO(
        sosId: 'sos_demo_${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phoneNumber ?? '0912345678',
        latitude: lat,
        longitude: lng,
        note: note,
        status: 'ACTIVE',
        address: 'Đường Kim Mã, Ba Đình, Hà Nội',
        timestamp: DateTime.now(),
      );
      if (Get.isRegistered<SosStreamService>()) {
        SosStreamService.to.sosList.insert(0, newSos);
      }
      return newSos;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/sos/alert',
        options: _options,
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
    if (DemoConfig.isDemoMode) {
      if (Get.isRegistered<SosStreamService>()) {
        SosStreamService.to.sosList.removeWhere((s) => s.sosId == sosId);
      }
      return;
    }
    try {
      await _dio.delete('$_baseUrl/sos/$sosId', options: _options);
    } catch (e) {
      throw Exception('Lỗi khi hủy SOS: $e');
    }
  }

  // 3. Gọi API PATCH /sos/{sosId}/status (Báo đã giải quyết)
  Future<void> resolveSosAlert(String sosId) async {
    if (DemoConfig.isDemoMode) {
      if (Get.isRegistered<SosStreamService>()) {
        SosStreamService.to.sosList.removeWhere((s) => s.sosId == sosId);
      }
      return;
    }
    try {
      await _dio.patch(
        '$_baseUrl/sos/$sosId/status',
        options: _options,
        queryParameters: {'status': 'RESOLVED'}, // Hoặc trạng thái backend bạn quy định
      );
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái SOS: $e');
    }
  }

  // Lấy danh sách SOS đang tồn tại
  Future<List<SosResponseDTO>> getActiveSosAlerts() async {
    if (DemoConfig.isDemoMode) {
      if (Get.isRegistered<SosStreamService>()) {
        return SosStreamService.to.sosList.toList();
      }
      return DemoConfig.getInitialSampleSosList();
    }
    try {
      final response = await _dio.get('$_baseUrl/sos/active', options: _options);
      final List data = response.data;
      return data.map((json) => SosResponseDTO.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách SOS: $e');
    }
  }
}