import 'package:flutter_test/flutter_test.dart';
import 'package:traffic_app/data/mock/mock_fines_data.dart';

void main() {
  group('Mock Fines Data Tests', () {
    test('isMockPlate recognizes all variations of 51C91820', () {
      expect(isMockPlate('51C91820'), isTrue);
      expect(isMockPlate('51C-918.20'), isTrue);
      expect(isMockPlate('51c-91820'), isTrue);
      expect(isMockPlate('51c91820'), isTrue);
      expect(isMockPlate('51C 918.20'), isTrue);
      expect(isMockPlate(' 51C-918.20 '), isTrue);

      expect(isMockPlate('51C91821'), isFalse);
      expect(isMockPlate('30A12345'), isFalse);
      expect(isMockPlate(''), isFalse);
      expect(isMockPlate(null), isFalse);
    });

    test('getMockFineResponseFor51C91820 loads violations from mock file', () async {
      final response = await getMockFineResponseFor51C91820();

      expect(response.status, equals(1));
      expect(response.hasViolations, isTrue);
      expect(response.data.length, equals(113));
      expect(response.dataInfo, isNotNull);
      expect(response.dataInfo!.total, equals(113));
      expect(response.dataInfo!.chuaXuPhat, equals(112));
      expect(response.dataInfo!.daXuPhat, equals(1));
      expect(response.licensePlate, equals('51C91820'));
      expect(response.vehicleName, equals('Ô tô'));

      // Check first violation
      final first = response.data.first;
      expect(first.index, equals(1));
      expect(first.violationCode, equals('12321.5.3.a.01'));
      expect(first.isPaid, isFalse);

      // Check last violation
      final last = response.data.last;
      expect(last.index, equals(113));
      expect(last.isPaid, isTrue);
    });

    test('getMockFineResponseFor51C91820 respects custom plate format', () async {
      final response = await getMockFineResponseFor51C91820(plate: '51C-918.20');
      expect(response.licensePlate, equals('51C-918.20'));
      expect(response.data.length, equals(113));
    });
  });
}
