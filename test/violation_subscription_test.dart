import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:traffic_app/data/datasources/violation_subscription_datasource.dart';
import 'package:traffic_app/data/models/violation_subscription_model.dart';
import 'package:traffic_app/data/repositories/violation_subscription_repository.dart';
import 'package:traffic_app/modules/violation_subscription/controllers/violation_subscription_controller.dart';
import 'package:traffic_app/services/storage_service.dart';

class FakeStorageService extends StorageService {
  String? _unsubscribed;

  @override
  Future<void> setUnsubscribedPlate(String plate) async {
    _unsubscribed = plate;
  }

  @override
  String? getUnsubscribedPlate() {
    return _unsubscribed;
  }

  @override
  Future<void> clearUnsubscribedPlate() async {
    _unsubscribed = null;
  }
}

class FakeViolationSubscriptionRemoteDataSource
    implements ViolationSubscriptionRemoteDataSource {
  final List<ViolationSubscription> storage = [];
  final List<String> callLogs = [];

  @override
  Future<List<ViolationSubscription>> getSubscriptions() async {
    callLogs.add('getSubscriptions');
    return List.from(storage);
  }

  @override
  Future<String> subscribe(ViolationSubscriptionRequest request) async {
    callLogs.add('subscribe:${request.licensePlate}:${request.receiveNotificationsForBoth}');
    // Backend sets enabled to true when subscribing
    storage.removeWhere((e) => e.licensePlate == request.licensePlate);
    storage.add(ViolationSubscription(
      id: 1,
      licensePlate: request.licensePlate,
      enabled: true,
    ));
    return 'Đăng ký thành công';
  }

  @override
  Future<String> unsubscribe(String licensePlate) async {
    callLogs.add('unsubscribe:$licensePlate');
    final clean = ViolationSubscription.normalizePlate(licensePlate);
    // Backend soft-disables by setting enabled = false
    final index = storage.indexWhere((e) => e.licensePlate == clean);
    if (index != -1) {
      storage[index] = storage[index].copyWith(enabled: false);
    }
    return 'Hủy theo dõi thành công';
  }

  @override
  Future<String> unsubscribeAll() async {
    callLogs.add('unsubscribeAll');
    for (int i = 0; i < storage.length; i++) {
      storage[i] = storage[i].copyWith(enabled: false);
    }
    return 'Đã hủy toàn bộ theo dõi';
  }

  @override
  Future<String> deleteTrackers() async {
    callLogs.add('deleteTrackers');
    return 'Đã xóa trackers theo dõi';
  }
}

void main() {
  group('ViolationSubscription Model & Plate Utility Tests', () {
    test('normalizePlate removes spaces, hyphens, dots and converts to uppercase', () {
      expect(ViolationSubscription.normalizePlate(' 51c - 918.20 '), '51C91820');
      expect(ViolationSubscription.normalizePlate('29-B1 123.45'), '29B112345');
      expect(ViolationSubscription.normalizePlate('30a.1234'), '30A1234');
      expect(ViolationSubscription.normalizePlate('80-A-123.45'), '80A12345');
    });

    test('isValidPlate accepts valid Vietnamese license plate formats', () {
      expect(ViolationSubscription.isValidPlate('51C91820'), isTrue);
      expect(ViolationSubscription.isValidPlate('51C - 918.20'), isTrue);
      expect(ViolationSubscription.isValidPlate('29B1-123.45'), isTrue);
      expect(ViolationSubscription.isValidPlate('30A1234'), isTrue);
      expect(ViolationSubscription.isValidPlate('43A12345'), isTrue);
    });

    test('isValidPlate rejects invalid plate strings', () {
      expect(ViolationSubscription.isValidPlate(''), isFalse);
      expect(ViolationSubscription.isValidPlate('123'), isFalse);
      expect(ViolationSubscription.isValidPlate('ABCDEF'), isFalse);
      expect(ViolationSubscription.isValidPlate('51-XYZ-123456789'), isFalse);
    });

    test('formattedPlate formats plate nicely', () {
      final sub1 = ViolationSubscription(id: 1, licensePlate: '51c91820', enabled: true);
      expect(sub1.formattedPlate, '51C-918.20');

      final sub2 = ViolationSubscription(id: 2, licensePlate: '29b112345', enabled: false);
      expect(sub2.formattedPlate, '29B1-123.45');
    });

    test('fromJson and toJson work correctly', () {
      final json = {
        'id': 10,
        'licensePlate': ' 51C - 918.20 ',
        'enabled': true,
      };

      final model = ViolationSubscription.fromJson(json);
      expect(model.id, 10);
      expect(model.licensePlate, '51C91820');
      expect(model.enabled, isTrue);

      final outJson = model.toJson();
      expect(outJson['id'], 10);
      expect(outJson['licensePlate'], '51C91820');
      expect(outJson['enabled'], isTrue);
    });
  });

  group('Single License Plate Subscription Repository Tests', () {
    late FakeViolationSubscriptionRemoteDataSource fakeDataSource;
    late ViolationSubscriptionRepository repository;

    setUp(() {
      fakeDataSource = FakeViolationSubscriptionRemoteDataSource();
      repository = ViolationSubscriptionRepository(dataSource: fakeDataSource);
    });

    test('subscribe registers a single license plate', () async {
      final result = await repository.subscribe(
        licensePlate: '51C-918.20',
        receiveNotificationsForBoth: true,
      );

      expect(result, 'Đăng ký thành công');
      final list = await repository.getSubscriptions();
      expect(list.length, 1);
      expect(list.first.licensePlate, '51C91820');
      expect(list.first.enabled, isTrue);
    });

    test('changePlate replaces old plate with new plate atomically', () async {
      // Đăng ký biển số ban đầu
      await repository.subscribe(
        licensePlate: '51C91820',
        receiveNotificationsForBoth: true,
      );

      expect(fakeDataSource.storage.length, 1);
      expect(fakeDataSource.storage.first.licensePlate, '51C91820');

      // Đổi sang biển số mới
      final changeResult = await repository.changePlate(
        oldPlate: '51C91820',
        newPlate: '29B1-123.45',
        receiveNotificationsForBoth: false,
      );

      expect(changeResult, 'Đăng ký thành công');
      final updatedList = await repository.getSubscriptions();
      // Đảm bảo chỉ có 1 biển số đang kích hoạt (active) duy nhất
      final activeList = updatedList.where((e) => e.enabled).toList();
      expect(activeList.length, 1);
      expect(activeList.first.licensePlate, '29B112345');
      expect(activeList.first.enabled, isTrue);
    });

    test('changePlate throws error for invalid new plate', () async {
      await repository.subscribe(
        licensePlate: '51C91820',
        receiveNotificationsForBoth: true,
      );

      expect(
        () => repository.changePlate(
          oldPlate: '51C91820',
          newPlate: 'INVALID',
          receiveNotificationsForBoth: true,
        ),
        throwsA(isA<String>()),
      );
    });

    test('unsubscribe removes the registered plate leaving list empty', () async {
      await repository.subscribe(
        licensePlate: '51C91820',
        receiveNotificationsForBoth: true,
      );

      final unsubResult = await repository.unsubscribe('51C-918.20');
      expect(unsubResult, 'Hủy theo dõi thành công');

      final list = await repository.getSubscriptions();
      // Backend soft-disables: enabled becomes false
      expect(list.first.enabled, isFalse);
    });
  });

  group('ViolationSubscriptionController Workflow Tests', () {
    late FakeViolationSubscriptionRemoteDataSource fakeDataSource;
    late ViolationSubscriptionRepository repository;
    late FakeStorageService fakeStorage;
    late ViolationSubscriptionController controller;

    setUp(() {
      Get.testMode = true;
      fakeDataSource = FakeViolationSubscriptionRemoteDataSource();
      repository = ViolationSubscriptionRepository(dataSource: fakeDataSource);
      fakeStorage = FakeStorageService();
      controller = ViolationSubscriptionController(
        repository: repository,
        storageService: fakeStorage,
      );
    });

    test('Initial loading with no subscription leaves list empty', () async {
      await controller.loadSubscriptions();
      expect(controller.subscriptions.isEmpty, isTrue);
      expect(controller.hasSubscription, isFalse);
    });

    test('Initial loading with active plate loads exactly 1 subscription', () async {
      fakeDataSource.storage.add(ViolationSubscription(
        id: 1,
        licensePlate: '51C91820',
        enabled: true,
      ));

      await controller.loadSubscriptions();
      expect(controller.subscriptions.length, 1);
      expect(controller.currentSubscription?.licensePlate, '51C91820');
      expect(controller.currentSubscription?.enabled, isTrue);
      expect(controller.hasSubscription, isTrue);
    });

    test('toggleNotificationStatus OFF calls unsubscribe (DELETE) and sets enabled=false', () async {
      final sub = ViolationSubscription(
        id: 1,
        licensePlate: '51C91820',
        enabled: true,
      );
      controller.subscriptions.add(sub);

      await controller.toggleNotificationStatus(sub, false);

      expect(fakeDataSource.callLogs, contains('unsubscribe:51C91820'));
      expect(controller.subscriptions.first.enabled, isFalse);
      expect(controller.receiveNotificationsForBoth.value, isFalse);
      expect(fakeStorage.getUnsubscribedPlate(), isNull);
    });

    test('toggleNotificationStatus ON calls subscribe (POST) and sets enabled=true', () async {
      final sub = ViolationSubscription(
        id: 1,
        licensePlate: '51C91820',
        enabled: false,
      );
      controller.subscriptions.add(sub);

      await controller.toggleNotificationStatus(sub, true);

      expect(fakeDataSource.callLogs, contains('subscribe:51C91820:true'));
      expect(controller.subscriptions.first.enabled, isTrue);
      expect(controller.receiveNotificationsForBoth.value, isTrue);
    });

    test('Unsubscribing plate records in storage and reload ignores soft-disabled server record', () async {
      fakeDataSource.storage.add(ViolationSubscription(
        id: 1,
        licensePlate: '51C91820',
        enabled: true,
      ));

      await controller.loadSubscriptions();
      expect(controller.subscriptions.length, 1);

      // Simulate delete execution
      await fakeStorage.setUnsubscribedPlate('51C91820');
      await repository.unsubscribe('51C91820');
      controller.subscriptions.removeWhere((e) => e.licensePlate == '51C91820');

      expect(controller.subscriptions.isEmpty, isTrue);
      expect(controller.hasSubscription, isFalse);

      // Reloading subscriptions from server should filter out 51C91820
      await controller.loadSubscriptions();
      expect(controller.subscriptions.isEmpty, isTrue);
      expect(controller.hasSubscription, isFalse);
    });

    test('Registering a new plate clears unsubscribed storage cache', () async {
      await fakeStorage.setUnsubscribedPlate('51C91820');
      expect(fakeStorage.getUnsubscribedPlate(), '51C91820');

      controller.plateController.text = '29B1-123.45';
      await controller.registerSubscription();

      expect(fakeStorage.getUnsubscribedPlate(), isNull);
      expect(controller.subscriptions.length, 1);
      expect(controller.currentSubscription?.licensePlate, '29B112345');
      expect(controller.hasSubscription, isTrue);
    });
  });
}
