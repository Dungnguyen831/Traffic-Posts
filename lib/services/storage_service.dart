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
  }) async {
    if (userId != null) await _prefs.setInt('user_id', userId);
    if (username != null) await _prefs.setString('user_username', username);
    if (fullname != null) await _prefs.setString('user_fullname', fullname);
    if (province != null) await _prefs.setString('user_province', province);
    if (relativePhone != null && relativePhone.isNotEmpty) {
      await _prefs.setString('user_relativePhone', relativePhone);
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _prefs.setString('user_phoneNumber', phoneNumber);
    }
  }

  String? getUsername() => _prefs.getString('user_username');

  int? getUserId() => _prefs.getInt('user_id');

  String? getFullName() =>
      _prefs.getString('user_fullname') ?? _prefs.getString('user_fullName');

  String? getProvince() => _prefs.getString('user_province');

  String? getRelativePhone() => _prefs.getString('user_relativePhone');

  String? getPhoneNumber() => _prefs.getString('user_phoneNumber');

  Future<void> clearUserInfo() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_username');
    await _prefs.remove('user_fullName');
    await _prefs.remove('user_province');
    await _prefs.remove('user_relativePhone');
    await _prefs.remove('user_phoneNumber');
  }
}
