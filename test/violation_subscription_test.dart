import 'package:flutter_test/flutter_test.dart';
import 'package:traffic_app/data/models/violation_subscription_model.dart';

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
}
