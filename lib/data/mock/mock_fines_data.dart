import '../models/fine_record_model.dart';

/// Kiểm tra biển số có phải là biển số mock 51C91820 hay không
/// Hỗ trợ tất cả các định dạng: 51C91820, 51C-918.20, 51c91820, 51C 91820...
bool isMockPlate(String? plate) {
  if (plate == null || plate.trim().isEmpty) return false;
  final clean = plate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  return clean == '51C91820';
}

/// Danh sách 10 lỗi vi phạm mặc định cho biển số 51C91820 (51C-918.20)
/// Dễ dàng chỉnh sửa, thêm, xóa các lỗi vi phạm bên dưới.
final List<FineRecord> mockViolationsFor51C91820 = [
  FineRecord(
    index: 1,
    occurredAt: '2024-10-15T09:24:00',
    violationCode: 'L01',
    violationDescription:
        '1. Điều khiển xe chạy quá tốc độ quy định từ 10 km/h đến 20 km/h (Chạy 74 km/h / Tốc độ tối đa 60 km/h)',
    location: 'Km 1827+200 Quốc lộ 1A, Huyện Bình Chánh, TP. Hồ Chí Minh',
    penalty:
        '4.000.000 - 6.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 01 tháng đến 03 tháng (Điểm đ Khoản 5 Điều 5 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Chưa xử phạt',
    statusCode: 'UNPROCESSED',
    detectedBy: 'Đội CSGT An Lạc - Phòng CSGT ĐB-ĐS Công an TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội Cảnh sát giao thông An Lạc',
        address:
            'B4/11 Quốc lộ 1A, Xã Tân Kiên, Huyện Bình Chánh, TP. Hồ Chí Minh',
        phone: '028 3760 0333',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 2,
    occurredAt: '2024-09-28T14:45:00',
    violationCode: 'L02',
    violationDescription:
        '2. Không chấp hành hiệu lệnh của đèn tín hiệu giao thông (Vượt đèn đỏ)',
    location:
        'Giao lộ Mai Chí Thọ - Đồng Văn Cống, Phường An Phú, TP. Thủ Đức, TP. Hồ Chí Minh',
    penalty:
        '4.000.000 - 6.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 01 tháng đến 03 tháng (Điểm a Khoản 5 Điều 5 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Chưa xử phạt',
    statusCode: 'UNPROCESSED',
    detectedBy: 'Đội CSGT Cát Lái - Phòng CSGT ĐB-ĐS Công an TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội Cảnh sát giao thông Cát Lái',
        address:
            '56 Đặng Như Mai, Phường Thạnh Mỹ Lợi, TP. Thủ Đức, TP. Hồ Chí Minh',
        phone: '028 3747 0088',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 3,
    occurredAt: '2024-08-19T10:12:00',
    violationCode: 'L03',
    violationDescription:
        '3. Điều khiển xe đi không đúng phần đường hoặc làn đường quy định (Đi sai làn đường)',
    location:
        'Đường Võ Văn Kiệt (đoạn giao Trần Đình Xu), Phường Cô Giang, Quận 1, TP. Hồ Chí Minh',
    penalty:
        '4.000.000 - 6.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 01 tháng đến 03 tháng (Điểm đ Khoản 5 Điều 5 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Chưa xử phạt',
    statusCode: 'UNPROCESSED',
    detectedBy: 'Đội CSGT Bến Thành - Phòng CSGT ĐB-ĐS Công an TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội Cảnh sát giao thông Bến Thành',
        address:
            '52-54 Nguyễn Khắc Nhu, Phường Cô Giang, Quận 1, TP. Hồ Chí Minh',
        phone: '028 3836 7111',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 4,
    occurredAt: '2024-07-22T06:35:00',
    violationCode: 'L04',
    violationDescription:
        '4. Đi vào đường có biển báo hiệu có nội dung cấm đi vào đối với loại phương tiện đang điều khiển (Đường cấm giờ theo tải trọng)',
    location:
        'Đường Cộng Hòa (ngã ba Hoàng Hoa Thám), Phường 13, Quận Tân Bình, TP. Hồ Chí Minh',
    penalty:
        '2.000.000 - 3.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 01 tháng đến 03 tháng (Điểm b Khoản 4 Điều 5 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Chưa xử phạt',
    statusCode: 'UNPROCESSED',
    detectedBy:
        'Đội CSGT Tân Sơn Nhất - Phòng CSGT ĐB-ĐS Công an TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội Cảnh sát giao thông Tân Sơn Nhất',
        address: '139 Phổ Quang, Phường 9, Quận Phú Nhuận, TP. Hồ Chí Minh',
        phone: '028 3844 4725',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 5,
    occurredAt: '2024-06-30T16:50:00',
    violationCode: 'L05',
    violationDescription:
        '5. Điều khiển xe chạy quá tốc độ quy định từ 05 km/h đến dưới 10 km/h (Chạy 67 km/h / Tốc độ tối đa 60 km/h)',
    location: 'Km 12+500 Cao tốc TP.HCM - Long Thành - Dầu Giây',
    penalty:
        '800.000 - 1.000.000 VNĐ (Điểm a Khoản 3 Điều 5 Nghị định 100/2019/NĐ-CP).',
    status: 'Chưa xử phạt',
    statusCode: 'UNPROCESSED',
    detectedBy: 'Đội TTKS Giao thông đường bộ cao tốc số 6 - Cục CSGT',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội TTKS GTĐB cao tốc số 6 - Cục Cảnh sát giao thông',
        address: 'Trạm thu phí Long Phước, TP. Thủ Đức, TP. Hồ Chí Minh',
        phone: '028 3731 0188',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 6,
    occurredAt: '2024-05-18T11:20:00',
    violationCode: 'L06',
    violationDescription:
        '6. Dừng xe, đỗ xe tại vị trí nơi có biển "Cấm dừng xe và đỗ xe"',
    location:
        'Số 150 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP. Hồ Chí Minh',
    penalty:
        '800.000 - 1.000.000 VNĐ (Điểm e Khoản 3 Điều 5 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Đã xử phạt',
    statusCode: 'PROCESSED',
    detectedBy: 'Đội CSGT - TT Công an Quận 1, TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội CSGT - TT Công an Quận 1',
        address: '73 Yersin, Phường Cầu Ông Lãnh, Quận 1, TP. Hồ Chí Minh',
        phone: '028 3821 7000',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 7,
    occurredAt: '2024-04-05T20:15:00',
    violationCode: 'L07',
    violationDescription:
        '7. Không tuân thủ các quy định về dừng xe, đỗ xe trên đường cao tốc',
    location:
        'Km 28+100 Cao tốc TP.HCM - Trung Lương, Huyện Bến Lức, Tỉnh Long An',
    penalty:
        '10.000.000 - 12.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 02 tháng đến 04 tháng (Điểm d Khoản 7 Điều 5 Nghị định 100/2019/NĐ-CP).',
    status: 'Đã xử phạt',
    statusCode: 'PROCESSED',
    detectedBy: 'Đội TTKS Giao thông đường bộ cao tốc số 7 - Cục CSGT',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội TTKS GTĐB cao tốc số 7 - Cục Cảnh sát giao thông',
        address:
            'Trạm Tân Tạo - Chợ Đệm, Huyện Bình Chánh, TP. Hồ Chí Minh',
        phone: '028 3754 4455',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 8,
    occurredAt: '2024-03-12T15:30:00',
    violationCode: 'L08',
    violationDescription:
        '8. Chuyển làn đường không có tín hiệu báo trước khi chạy trên đường cao tốc',
    location: 'Km 08+200 Cao tốc TP.HCM - Long Thành - Dầu Giây',
    penalty:
        '4.000.000 - 6.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 01 tháng đến 03 tháng (Điểm g Khoản 5 Điều 5 Nghị định 100/2019/NĐ-CP).',
    status: 'Đã xử phạt',
    statusCode: 'PROCESSED',
    detectedBy: 'Đội TTKS Giao thông đường bộ cao tốc số 6 - Cục CSGT',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội TTKS GTĐB cao tốc số 6 - Cục Cảnh sát giao thông',
        address: 'Trạm thu phí Long Phước, TP. Thủ Đức, TP. Hồ Chí Minh',
        phone: '028 3731 0188',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 9,
    occurredAt: '2024-02-20T08:10:00',
    violationCode: 'L09',
    violationDescription:
        '9. Không chấp hành hiệu lệnh, chỉ dẫn của biển báo hiệu, vạch kẻ đường (Đè vạch kênh hóa dòng xe / vạch xương cá)',
    location:
        'Nút giao An Phú, Đường Mai Chí Thọ, TP. Thủ Đức, TP. Hồ Chí Minh',
    penalty:
        '300.000 - 400.000 VNĐ (Điểm a Khoản 1 Điều 5 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Đã xử phạt',
    statusCode: 'PROCESSED',
    detectedBy: 'Đội CSGT Cát Lái - Phòng CSGT ĐB-ĐS Công an TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội Cảnh sát giao thông Cát Lái',
        address:
            '56 Đặng Như Mai, Phường Thạnh Mỹ Lợi, TP. Thủ Đức, TP. Hồ Chí Minh',
        phone: '028 3747 0088',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
  FineRecord(
    index: 10,
    occurredAt: '2024-01-10T13:40:00',
    violationCode: 'L10',
    violationDescription:
        '10. Chở hàng vượt quá chiều cao xếp hàng cho phép đối với xe ô tô tải',
    location:
        'Quốc lộ 13, Phường Hiệp Bình Phước, TP. Thủ Đức, TP. Hồ Chí Minh',
    penalty:
        '2.000.000 - 3.000.000 VNĐ. Tước quyền sử dụng Giấy phép lái xe từ 01 tháng đến 03 tháng (Điểm b Khoản 4 Điều 24 Nghị định 100/2019/NĐ-CP được sửa đổi bởi Nghị định 123/2021/NĐ-CP).',
    status: 'Đã xử phạt',
    statusCode: 'PROCESSED',
    detectedBy:
        'Đội CSGT Bình Triệu - Phòng CSGT ĐB-ĐS Công an TP. Hồ Chí Minh',
    resolutionUnits: [
      ResolutionUnit(
        name: 'Đội Cảnh sát giao thông Bình Triệu',
        address:
            '41 Quốc lộ 1A, Phường Linh Xuân, TP. Thủ Đức, TP. Hồ Chí Minh',
        phone: '028 3727 2000',
      ),
    ],
    bienKiemSoat: '51C-918.20',
    loaiPhuongTien: 'Ô tô tải',
    mauBien: 'Biển trắng, chữ và số màu đen',
  ),
];

/// Trả về đối tượng FineResponse hoàn chỉnh cho biển số 51C91820
FineResponse getMockFineResponseFor51C91820({
  String? plate,
  String? vehicle,
}) {
  final resolvedPlate =
      (plate != null && plate.trim().isNotEmpty) ? plate.trim().toUpperCase() : '51C-918.20';
  final resolvedVehicle = vehicle ?? '1';

  final chuaXuPhat =
      mockViolationsFor51C91820.where((r) => !r.isPaid).length;
  final daXuPhat =
      mockViolationsFor51C91820.where((r) => r.isPaid).length;

  return FineResponse(
    status: 1,
    msg: 'Tìm thấy ${mockViolationsFor51C91820.length} lỗi vi phạm',
    data: mockViolationsFor51C91820,
    dataInfo: FineDataInfo(
      total: mockViolationsFor51C91820.length,
      chuaXuPhat: chuaXuPhat,
      daXuPhat: daXuPhat,
      latest: mockViolationsFor51C91820.isNotEmpty
          ? mockViolationsFor51C91820.first.formattedOccurredAt
          : '',
    ),
    licensePlate: resolvedPlate,
    vehicle: resolvedVehicle,
    vehicleName: 'Ô tô tải',
    thisMonthViolations: 1,
    previousMonthViolations: 2,
  );
}
