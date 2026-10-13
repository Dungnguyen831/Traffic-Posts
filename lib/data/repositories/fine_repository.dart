import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../config/demo_config.dart';
import '../models/fine_record_model.dart';

class FineRepository {
  static const String _baseUrl = 'https://api.checkphatnguoi.vn';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType
          .plain, // nhận raw string, tự decode để tránh lỗi content-type
    ),
  );

  Future<FineResponse> lookupFines(String licensePlate) async {
    final plate = licensePlate.trim().toUpperCase();

    if (DemoConfig.isDemoMode) {
      final hasViolation = plate.contains('88') ||
          plate.contains('68') ||
          plate.contains('99') ||
          plate.contains('123');
      return FineResponse(
        status: hasViolation ? 1 : 2,
        msg: hasViolation
            ? 'Tìm thấy lỗi vi phạm giao thông (Mô phỏng Web Demo)'
            : 'Phương tiện không có lỗi vi phạm phạt nguội',
        dataInfo: FineDataInfo(
          total: hasViolation ? 1 : 0,
          chuaXuPhat: hasViolation ? 1 : 0,
          daXuPhat: 0,
          latest: '10:15 11/10/2026',
        ),
        data: hasViolation
            ? [
                FineRecord(
                  bienKiemSoat: plate,
                  mauBien: 'Biển trắng',
                  loaiPhuongTien: 'Ô tô con',
                  thoiGianViPham: '10:15 11/10/2026',
                  diaDiemViPham:
                      'Ngã tư Nguyễn Chí Thanh - Huỳnh Thúc Kháng, Đống Đa, Hà Nội',
                  hanhViViPham:
                      'Không chấp hành hiệu lệnh của đèn tín hiệu giao thông (Vượt đèn đỏ)',
                  trangThai: 'Chưa xử phạt',
                  donViPhatHien: 'Đội Cảnh sát Giao thông Số 3 - CA TP. Hà Nội',
                  noiGiaiQuyet: [
                    'Số 1234 Đường Láng, Đống Đa, TP. Hà Nội (SĐT: 024.3835.xxxx)'
                  ],
                ),
              ]
            : [],
      );
    }
    try {
      final response = await _dio.post(
        '$_baseUrl/phatnguoi',
        data: {'bienso': plate},
      );
      final Map<String, dynamic> json =
          jsonDecode(response.data as String) as Map<String, dynamic>;
      return FineResponse.fromJson(json);
    } on DioException catch (e) {
      throw e.message ?? 'discovery_error_network'.tr;
    }
  }
}
