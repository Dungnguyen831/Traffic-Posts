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

    test('mockViolationsFor51C91820 has 10 violations with complete info', () {
      expect(mockViolationsFor51C91820.length, equals(10));

      for (var i = 0; i < mockViolationsFor51C91820.length; i++) {
        final v = mockViolationsFor51C91820[i];
        expect(v.index, equals(i + 1));
        expect(v.violationCode, isNotEmpty);
        expect(v.violationDescription, isNotEmpty);
        expect(v.location, isNotEmpty);
        expect(v.penalty, isNotEmpty);
        expect(v.detectedBy, isNotEmpty);
        expect(v.resolutionUnits, isNotEmpty);
        expect(v.bienKiemSoat, contains('51C'));
      }

      final unpaid = mockViolationsFor51C91820.where((r) => !r.isPaid).length;
      final paid = mockViolationsFor51C91820.where((r) => r.isPaid).length;

      expect(unpaid, equals(5));
      expect(paid, equals(5));
    });

    test('getMockFineResponseFor51C91820 returns properly populated FineResponse', () {
      final response = getMockFineResponseFor51C91820(plate: '51C-918.20');

      expect(response.status, equals(1));
      expect(response.hasViolations, isTrue);
      expect(response.data.length, equals(10));
      expect(response.dataInfo, isNotNull);
      expect(response.dataInfo!.total, equals(10));
      expect(response.dataInfo!.chuaXuPhat, equals(5));
      expect(response.dataInfo!.daXuPhat, equals(5));
      expect(response.licensePlate, equals('51C-918.20'));
      expect(response.vehicleName, equals('Ô tô tải'));
    });
  });
}
