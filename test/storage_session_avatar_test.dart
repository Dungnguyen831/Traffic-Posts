import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traffic_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService user session & avatar isolation', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService().init();
    });

    test(
      'saveUserInfo with clearAvatarIfEmpty=true removes stale avatar when null or empty',
      () async {
        await storage.saveUserInfo(
          userId: 1,
          username: 'old_user',
          avatarUrl: 'http://160.250.5.189/uploads/old_avatar.jpg',
        );
        expect(
          storage.getAvatarUrl(),
          'http://160.250.5.189/uploads/old_avatar.jpg',
        );

        // Partial update without clearAvatarIfEmpty keeps existing avatar
        await storage.saveUserInfo(fullname: 'Updated Name');
        expect(
          storage.getAvatarUrl(),
          'http://160.250.5.189/uploads/old_avatar.jpg',
        );

        // Authoritative sync with null avatar clears stale avatar
        await storage.saveUserInfo(
          userId: 1,
          avatarUrl: null,
          clearAvatarIfEmpty: true,
        );
        expect(storage.getAvatarUrl(), isNull);
      },
    );

    test(
      'clearUserInfo wipes previous userId and avatarUrl while preserving token',
      () async {
        await storage.setToken('new_account_jwt');
        await storage.saveUserInfo(
          userId: 1,
          username: 'old_user',
          fullname: 'Old User',
          avatarUrl: 'http://160.250.5.189/uploads/old_avatar.jpg',
          phoneNumber: '0900000000',
          relativePhone: '0911111111',
        );

        await storage.clearUserInfo();

        expect(storage.getToken(), 'new_account_jwt');
        expect(storage.getUserId(), isNull);
        expect(storage.getUsername(), isNull);
        expect(storage.getFullName(), isNull);
        expect(storage.getAvatarUrl(), isNull);
        expect(storage.getPhoneNumber(), isNull);
        expect(storage.getRelativePhone(), isNull);
      },
    );

    test('clearAvatarUrl removes only user_avatarUrl', () async {
      await storage.saveUserInfo(
        userId: 2,
        username: 'user2',
        avatarUrl: 'http://160.250.5.189/uploads/avatar2.jpg',
      );

      await storage.clearAvatarUrl();

      expect(storage.getAvatarUrl(), isNull);
      expect(storage.getUserId(), 2);
      expect(storage.getUsername(), 'user2');
    });
  });
}
