import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  // Getter để dễ dàng truy cập từ bất kỳ đâu trong app
  static StorageService get to => Get.find<StorageService>();

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> setToken(String token) async {
    await _prefs.setString('token', token);
  }

  String? getToken() {
    return _prefs.getString('token');
  }

  Future<void> removeToken() async {
    await _prefs.remove('token');
  }

  Future<void> saveCredentials(String username, String password) async {
    await _prefs.setString('username', username);
    await _prefs.setString('password', password);
  }

  Map<String, String>? getCredentials() {
    final username = _prefs.getString('username');
    final password = _prefs.getString('password');
    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _prefs.remove('username');
    await _prefs.remove('password');
  }

  // Active SOS session storage gắn liền với danh tính tài khoản
  Future<void> saveActiveSos({
    required String sosId,
    required double lat,
    required double lng,
    String? note,
    int? userId,
    String? phoneNumber,
    String? username,
  }) async {
    await _prefs.setString('active_sos_id', sosId);
    await _prefs.setDouble('active_sos_lat', lat);
    await _prefs.setDouble('active_sos_lng', lng);
    if (note != null) {
      await _prefs.setString('active_sos_note', note);
    }
    if (userId != null) {
      await _prefs.setInt('active_sos_user_id', userId);
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _prefs.setString('active_sos_user_phone', phoneNumber);
    }
    if (username != null && username.isNotEmpty) {
      await _prefs.setString('active_sos_username', username);
    }
  }

  Map<String, dynamic>? getActiveSos() {
    final sosId = _prefs.getString('active_sos_id');
    final lat = _prefs.getDouble('active_sos_lat');
    final lng = _prefs.getDouble('active_sos_lng');
    final note = _prefs.getString('active_sos_note');
    final userId = _prefs.getInt('active_sos_user_id');
    final userPhone = _prefs.getString('active_sos_user_phone');
    final username = _prefs.getString('active_sos_username');

    if (sosId != null && lat != null && lng != null) {
      return {
        'sosId': sosId,
        'lat': lat,
        'lng': lng,
        'note': note ?? '',
        'userId': userId,
        'userPhone': userPhone,
        'username': username,
      };
    }
    return null;
  }

  Future<void> clearActiveSos() async {
    await _prefs.remove('active_sos_id');
    await _prefs.remove('active_sos_lat');
    await _prefs.remove('active_sos_lng');
    await _prefs.remove('active_sos_note');
    await _prefs.remove('active_sos_user_id');
    await _prefs.remove('active_sos_user_phone');
    await _prefs.remove('active_sos_username');
  }

  // Province/Location storage
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // User information storage
  Future<void> saveUserInfo({
    int? userId,
    String? username,
    String? fullname,
    String? province,
    String? relativePhone,
    String? phoneNumber,
    int? reputationScore,
    String? badge,
    bool? canCreatePost,
  }) async {
    if (userId != null) await _prefs.setInt('user_id', userId);
    if (username != null) await _prefs.setString('user_username', username);
    if (fullname != null) {
      await _prefs.setString('user_fullname', fullname);
      await _prefs.setString('user_fullName', fullname);
    }
    if (province != null) await _prefs.setString('user_province', province);
    if (relativePhone != null && relativePhone.isNotEmpty) {
      await _prefs.setString('user_relativePhone', relativePhone);
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _prefs.setString('user_phoneNumber', phoneNumber);
    }
    if (reputationScore != null) {
      await _prefs.setInt('user_reputationScore', reputationScore);
    }
    if (badge != null && badge.isNotEmpty) {
      await _prefs.setString('user_badge', badge);
    }
    if (canCreatePost != null) {
      await _prefs.setBool('user_canCreatePost', canCreatePost);
    }
  }

  Future<void> saveUserReputation({
    int? score,
    String? badge,
    bool? canCreatePost,
  }) async {
    if (score != null) await _prefs.setInt('user_reputationScore', score);
    if (badge != null && badge.isNotEmpty) {
      await _prefs.setString('user_badge', badge);
    }
    if (canCreatePost != null) {
      await _prefs.setBool('user_canCreatePost', canCreatePost);
    }
  }

  String? getUsername() => _prefs.getString('user_username');

  int? getUserId() => _prefs.getInt('user_id');

  String? getFullName() =>
      _prefs.getString('user_fullname') ?? _prefs.getString('user_fullName');

  String? getProvince() => _prefs.getString('user_province');

  String? getRelativePhone() => _prefs.getString('user_relativePhone');

  String? getPhoneNumber() => _prefs.getString('user_phoneNumber');

  int getReputationScore() => _prefs.getInt('user_reputationScore') ?? 100;

  String getBadge() => _prefs.getString('user_badge') ?? 'Người dẫn đường';

  bool canCreatePost() {
    return _prefs.getBool('user_canCreatePost') ?? (getReputationScore() >= 80);
  }

  Future<void> clearUserInfo() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_username');
    await _prefs.remove('user_fullname');
    await _prefs.remove('user_fullName');
    await _prefs.remove('user_province');
    await _prefs.remove('user_relativePhone');
    await _prefs.remove('user_phoneNumber');
    await _prefs.remove('user_reputationScore');
    await _prefs.remove('user_badge');
    await _prefs.remove('user_canCreatePost');
  }
}
