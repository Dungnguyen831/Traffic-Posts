import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/location_model.dart';
import '../data/models/sos_model.dart';
import '../data/models/traffic_post_model.dart';
import '../data/models/user_info_model.dart';

/// Cấu hình và Dữ liệu Mẫu cho chế độ Web Demo
class DemoConfig {
  /// Biến cờ kiểm tra môi trường: Mặc định bật khi chạy trên Web
  static bool _forceDemoMode = false;

  /// Kích hoạt Demo Mode nếu kIsWeb == true hoặc được bật thủ công
  static bool get isDemoMode => kIsWeb || _forceDemoMode;

  static set forceDemoMode(bool value) {
    _forceDemoMode = value;
  }

  // ─── Tọa độ trung tâm cố định (Hà Nội: Kim Mã - Ba Đình) ───────────────────
  static const LatLng defaultCenter = LatLng(21.028511, 105.804817);
  static const String defaultAddress = 'Đường Kim Mã, Ba Đình, Hà Nội';

  // ─── Lộ trình mô phỏng phương tiện (Để trống vì dùng vị trí cố định) ─────────
  static const List<LatLng> simulatedRoute = [];

  /// Ảnh đại diện demo của người dùng
  static const String demoUserAvatar = 'assets/icons/avatar_demo.jpg';

  /// Vị trí hiện tại của người dùng (Cố định ở trung tâm bản đồ)
  static LatLng currentSimulatedPosition = defaultCenter;

  // ─── Dữ liệu mẫu bài viết giao thông ban đầu với ảnh thực tế ───────────────
  static List<TrafficPostModel> getInitialSamplePosts() {
    return [
      TrafficPostModel(
        id: 'sample_ketxe_1',
        userId: '101',
        userName: 'Nguyễn Văn Nam',
        avatarUrl: demoUserAvatar,
        content:
            'Kẹt xe nghiêm trọng tại Ngã tư Cầu Giấy hướng về Kim Mã, các phương tiện chen chúc di chuyển rất chậm chạp.',
        hashtags: ['ketxe'],
        imageUrls: ['assets/icons/traffic_ketxe.jpg'],
        location: LocationModel(
          lat: 21.033500,
          lng: 105.800500,
          address: 'Ngã tư Cầu Giấy, Hà Nội',
        ),
        likes: 18,
        isLiked: false,
        userReputationScore: 145,
        userBadge: 'Chuyên gia giao thông',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      TrafficPostModel(
        id: 'sample_tainan_1',
        userId: '102',
        userName: 'Trần Thị Mai',
        avatarUrl: demoUserAvatar,
        content:
            'Hiện trường va chạm giao thông giữa 2 phương tiện tại nút giao Kim Mã - Liễu Giai, đường ùn ứ một làn xe.',
        hashtags: ['tainan', 'baocaotainan'],
        imageUrls: ['assets/icons/traffic_tainan.jpg'],
        location: LocationModel(
          lat: 21.031500,
          lng: 105.813000,
          address: 'Kim Mã - Liễu Giai, Ba Đình, Hà Nội',
        ),
        likes: 9,
        isLiked: true,
        userReputationScore: 112,
        userBadge: 'Người dẫn đường',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      TrafficPostModel(
        id: 'sample_ngaplutnuoc_1',
        userId: '103',
        userName: 'Lê Hoàng Anh',
        avatarUrl: demoUserAvatar,
        content:
            'Đoạn đường ven sông Tô Lịch ngập nước sâu 30-40cm sau mưa lớn, người dân bì bõm dắt xe, các xe gầm thấp chú ý đi đường khác.',
        hashtags: ['ngaplutnuoc'],
        imageUrls: ['assets/icons/traffic_ngaplut.jpg'],
        location: LocationModel(
          lat: 21.025000,
          lng: 105.802000,
          address: 'Đường Láng, Cầu Giấy, Hà Nội',
        ),
        likes: 31,
        isLiked: false,
        userReputationScore: 138,
        userBadge: 'Chuyên gia giao thông',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      TrafficPostModel(
        id: 'sample_giaothong_1',
        userId: '104',
        userName: 'Đội CSGT Số 2',
        avatarUrl: demoUserAvatar,
        content:
            'Lực lượng CSGT và xe tuần tra công vụ đang túc trực điều tiết phân luồng giờ cao điểm nút giao Liễu Giai - Đào Tấn, các phương tiện đi lại ổn định.',
        hashtags: ['giaothong'],
        imageUrls: ['assets/icons/traffic_giaothong.jpg'],
        location: LocationModel(
          lat: 21.029500,
          lng: 105.810000,
          address: 'Đường Kim Mã, Ba Đình, Hà Nội',
        ),
        likes: 54,
        isLiked: false,
        userReputationScore: 185,
        userBadge: 'Chuyên gia giao thông',
        timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      TrafficPostModel(
        id: 'sample_sos_1',
        userId: '105',
        userName: 'Phạm Quốc Huy',
        avatarUrl: demoUserAvatar,
        content:
            'Xe máy bị đinh thủng lốp cần hỗ trợ vá săm lưu động gấp gần cây xăng Giảng Võ.',
        hashtags: ['sos'],
        imageUrls: ['assets/icons/traffic_sos.jpg'],
        location: LocationModel(
          lat: 21.027000,
          lng: 105.818000,
          address: 'Giảng Võ, Đống Đa, Hà Nội',
        ),
        likes: 12,
        isLiked: false,
        userReputationScore: 105,
        userBadge: 'Người dẫn đường',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
    ];
  }

  /// Danh sách bảng xếp hạng người dùng mẫu cho Web Demo
  static List<UserInfoModel> getSampleRankingUsers() {
    return [
      UserInfoModel(
        id: 104,
        username: 'csgt_so2',
        fullname: 'Đội CSGT Số 2',
        avatarUrl: demoUserAvatar,
        follow: true,
        followersCount: 1580,
        followingsCount: 12,
        reputationScore: 185,
        badge: 'Chuyên gia giao thông',
        canCreatePost: true,
      ),
      UserInfoModel(
        id: 101,
        username: 'vannam_hn',
        fullname: 'Nguyễn Văn Nam',
        avatarUrl: demoUserAvatar,
        follow: true,
        followersCount: 420,
        followingsCount: 85,
        reputationScore: 145,
        badge: 'Chuyên gia giao thông',
        canCreatePost: true,
      ),
      UserInfoModel(
        id: 103,
        username: 'hoanganh_le',
        fullname: 'Lê Hoàng Anh',
        avatarUrl: demoUserAvatar,
        follow: false,
        followersCount: 310,
        followingsCount: 64,
        reputationScore: 138,
        badge: 'Chuyên gia giao thông',
        canCreatePost: true,
      ),
      UserInfoModel(
        id: 1,
        username: 'demo_user',
        fullname: 'Người dùng Demo',
        avatarUrl: demoUserAvatar,
        follow: false,
        followersCount: 128,
        followingsCount: 45,
        reputationScore: 125,
        badge: 'Chuyên gia giao thông',
        canCreatePost: true,
      ),
      UserInfoModel(
        id: 102,
        username: 'maitran_bd',
        fullname: 'Trần Thị Mai',
        avatarUrl: demoUserAvatar,
        follow: true,
        followersCount: 195,
        followingsCount: 92,
        reputationScore: 112,
        badge: 'Người dẫn đường',
        canCreatePost: true,
      ),
      UserInfoModel(
        id: 105,
        username: 'quochuy_pham',
        fullname: 'Phạm Quốc Huy',
        avatarUrl: demoUserAvatar,
        follow: false,
        followersCount: 88,
        followingsCount: 53,
        reputationScore: 105,
        badge: 'Người dẫn đường',
        canCreatePost: true,
      ),
      UserInfoModel(
        id: 106,
        username: 'ducminh_vu',
        fullname: 'Vũ Đức Minh',
        avatarUrl: demoUserAvatar,
        follow: false,
        followersCount: 64,
        followingsCount: 41,
        reputationScore: 98,
        badge: 'Người dẫn đường',
        canCreatePost: true,
      ),
    ];
  }

  // ─── Kho sự kiện mô phỏng phát sinh định kỳ (kèm ảnh thực tế) ─────────────
  static final List<Map<String, dynamic>> dynamicTrafficEventsPool = [
    {
      'title': 'Ùn tắc giờ cao điểm',
      'tag': 'ketxe',
      'content':
          'Ùn tắc cục bộ tại nút giao Chùa Bộc - Phạm Ngọc Thạch, dòng phương tiện đông đúc kéo dài.',
      'lat': 21.008500,
      'lng': 105.829000,
      'address': 'Chùa Bộc, Đống Đa, Hà Nội',
      'userName': 'Nguyễn Hoàng Long',
      'avatarUrl': demoUserAvatar,
      'imageUrls': ['assets/icons/traffic_un_tac.jpg'],
    },
    {
      'title': 'Ngập úng sau mưa rào',
      'tag': 'ngaplutnuoc',
      'content':
          'Điểm ngập úng ngã tư Thái Hà - Tây Sơn ngập sâu 25cm, nhiều phương tiện chết máy phải dắt bộ.',
      'lat': 21.012500,
      'lng': 105.822000,
      'address': 'Ngã tư Thái Hà - Tây Sơn, Đống Đa, Hà Nội',
      'userName': 'Vũ Đức Minh',
      'avatarUrl': demoUserAvatar,
      'imageUrls': ['assets/icons/traffic_ngap_ung.jpg'],
    },
    {
      'title': 'Sự cố va chạm',
      'tag': 'tainan',
      'content':
          'Hiện trường va chạm xe máy tại đường Nguyễn Chí Thanh hướng lên cầu vượt, các xe nên chú ý giảm tốc độ quan sát.',
      'lat': 21.023500,
      'lng': 105.807500,
      'address': 'Nguyễn Chí Thanh, Ba Đình, Hà Nội',
      'userName': 'Đỗ Mai Hương',
      'avatarUrl': demoUserAvatar,
      'imageUrls': ['assets/icons/traffic_va_cham.jpg'],
    },
    {
      'title': 'Ùn ứ đường Vành Đai',
      'tag': 'ketxe',
      'content':
          'Lối lên cầu Vành Đai 2 trên cao đoạn Bưởi - Cầu Giấy xe cộ di chuyển chậm do mật độ xe tăng cao.',
      'lat': 21.041000,
      'lng': 105.804000,
      'address': 'Đường Bưởi, Ba Đình, Hà Nội',
      'userName': 'Trần Bá Thắng',
      'avatarUrl': demoUserAvatar,
      'imageUrls': ['assets/icons/traffic_vanhdai.jpg'],
    },
    {
      'title': 'Cảnh báo ngập vỉa hè',
      'tag': 'ngaplutnuoc',
      'content':
          'Đoạn đường ven hồ Ngọc Khánh nước tràn lên mặt đường khoảng 20cm, người tham gia giao thông cẩn thận ngã trượt.',
      'lat': 21.029800,
      'lng': 105.814500,
      'address': 'Hồ Ngọc Khánh, Ba Đình, Hà Nội',
      'userName': 'Bùi Thanh Tùng',
      'avatarUrl': demoUserAvatar,
      'imageUrls': ['assets/icons/traffic_ngaplut.jpg'],
    },
    {
      'title': 'Cứu hộ khẩn cấp',
      'tag': 'sos',
      'content':
          'Xe máy gặp sự cố hỏng săm tại phố Đào Tấn gần Lotte Center, cần đội thợ hỗ trợ vá lưu động.',
      'lat': 21.033200,
      'lng': 105.811000,
      'address': 'Đào Tấn, Ba Đình, Hà Nội',
      'userName': 'Lê Minh Tuấn',
      'avatarUrl': demoUserAvatar,
      'imageUrls': ['assets/icons/traffic_sos.jpg'],
    },
  ];

  // ─── Danh sách SOS mẫu ban đầu ──────────────────────────────────────────
  static List<SosResponseDTO> getInitialSampleSosList() {
    return [
      SosResponseDTO(
        sosId: 'sample_sos_alert_1',
        phoneNumber: '0987654321',
        latitude: 21.027000,
        longitude: 105.818000,
        note: 'Xe máy bị sự cố chết máy cần hỗ trợ lưu động gần Giảng Võ',
        status: 'ACTIVE',
        address: 'Giảng Võ, Đống Đa, Hà Nội',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      SosResponseDTO(
        sosId: 'sample_sos_alert_2',
        phoneNumber: '0912345678',
        latitude: 21.034500,
        longitude: 105.808500,
        note: 'Cần hỗ trợ đưa người va quẹt giao thông vào trạm y tế gần nhất',
        status: 'ACTIVE',
        address: 'Đường Đội Cấn, Ba Đình, Hà Nội',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    ];
  }
}
