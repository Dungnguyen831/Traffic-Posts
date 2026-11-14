import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:traffic_app/data/models/location_model.dart';
import 'package:traffic_app/data/models/traffic_post_model.dart';
import 'package:traffic_app/modules/map/controllers/map_controller.dart';
import 'package:traffic_app/utils/hashtag_helper.dart';

void main() {
  group('Map Filter Logic Tests', () {
    final now = DateTime.now();

    final post30MinAgo = TrafficPostModel(
      id: 'post_30m',
      content: 'Kẹt xe ngã tư',
      type: 'traffic',
      hashtags: ['#ketxe'],
      timestamp: now.subtract(const Duration(minutes: 30)),
      location: LocationModel(
        lat: 21.028511,
        lng: 105.804817,
        address: 'Hà Nội',
      ),
    );

    final post3HoursAgo = TrafficPostModel(
      id: 'post_3h',
      content: 'Tai nạn xe máy',
      type: 'accident',
      hashtags: ['#tainan'],
      timestamp: now.subtract(const Duration(hours: 3)),
      location: LocationModel(
        lat: 21.030000,
        lng: 105.810000,
        address: 'Cầu Giấy',
      ),
    );

    final post12HoursAgo = TrafficPostModel(
      id: 'post_12h',
      content: 'Ngập nước sâu',
      type: 'flood',
      hashtags: ['#ngaplutnuoc'],
      timestamp: now.subtract(const Duration(hours: 12)),
      location: LocationModel(
        lat: 21.050000,
        lng: 105.820000,
        address: 'Tây Hồ',
      ),
    );

    final post2DaysAgo = TrafficPostModel(
      id: 'post_2d',
      content: 'Cảnh báo nguy hiểm',
      type: 'warning',
      hashtags: ['#baocaotainan'],
      timestamp: now.subtract(const Duration(days: 2)),
      location: LocationModel(
        lat: 20.980000,
        lng: 105.750000,
        address: 'Hà Đông',
      ),
    );

    final posts = [post30MinAgo, post3HoursAgo, post12HoursAgo, post2DaysAgo];

    test(
      'Tag options exclude giaothong and include standard incident types',
      () {
        final tags = MapController.filterTagOptions.map((o) => o.tag).toList();
        expect(tags, isNot(contains('giaothong')));
        expect(
          tags,
          containsAll([
            null,
            'ketxe',
            'tainan',
            'ngaplutnuoc',
            'baocaotainan',
            'sos',
          ]),
        );
      },
    );

    test('Filter by Time: 1 hour ago', () {
      const filter = MapTimeFilter.last1Hour;
      final filtered = posts.where((p) {
        final ts = p.timestamp;
        if (ts == null) return false;
        final diff = DateTime.now().difference(ts);
        if (diff.isNegative) return true;
        switch (filter) {
          case MapTimeFilter.last1Hour:
            return diff <= const Duration(hours: 1);
          case MapTimeFilter.last5Hours:
            return diff <= const Duration(hours: 5);
          case MapTimeFilter.last1Day:
            return diff <= const Duration(days: 1);
          case MapTimeFilter.all:
            return true;
        }
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'post_30m');
    });

    test('Filter by Time: 5 hours ago', () {
      const filter = MapTimeFilter.last5Hours;
      final filtered = posts.where((p) {
        final ts = p.timestamp;
        if (ts == null) return false;
        final diff = DateTime.now().difference(ts);
        if (diff.isNegative) return true;
        switch (filter) {
          case MapTimeFilter.last1Hour:
            return diff <= const Duration(hours: 1);
          case MapTimeFilter.last5Hours:
            return diff <= const Duration(hours: 5);
          case MapTimeFilter.last1Day:
            return diff <= const Duration(days: 1);
          case MapTimeFilter.all:
            return true;
        }
      }).toList();

      expect(filtered.length, 2);
      expect(filtered.map((p) => p.id), containsAll(['post_30m', 'post_3h']));
    });

    test('Filter by Time: 1 day ago (24 hours)', () {
      const filter = MapTimeFilter.last1Day;
      final filtered = posts.where((p) {
        final ts = p.timestamp;
        if (ts == null) return false;
        final diff = DateTime.now().difference(ts);
        if (diff.isNegative) return true;
        switch (filter) {
          case MapTimeFilter.last1Hour:
            return diff <= const Duration(hours: 1);
          case MapTimeFilter.last5Hours:
            return diff <= const Duration(hours: 5);
          case MapTimeFilter.last1Day:
            return diff <= const Duration(days: 1);
          case MapTimeFilter.all:
            return true;
        }
      }).toList();

      expect(filtered.length, 3);
      expect(
        filtered.map((p) => p.id),
        containsAll(['post_30m', 'post_3h', 'post_12h']),
      );
    });

    test('Filter by Tag: #ketxe / #tainan using HashtagHelper', () {
      final canonicalKetXe = HashtagHelper.toCanonical('ketxe');
      final ketXePosts = posts.where((p) {
        final tags = (p.hashtags ?? []).map(HashtagHelper.toCanonical);
        return tags.contains(canonicalKetXe);
      }).toList();

      expect(ketXePosts.length, 1);
      expect(ketXePosts.first.id, 'post_30m');

      final canonicalTaiNan = HashtagHelper.toCanonical('tai nan');
      final taiNanPosts = posts.where((p) {
        final tags = (p.hashtags ?? []).map(HashtagHelper.toCanonical);
        return tags.contains(canonicalTaiNan);
      }).toList();

      expect(taiNanPosts.length, 1);
      expect(taiNanPosts.first.id, 'post_3h');
    });

    test('Filter by Radius around User Location', () {
      const geoDistance = Distance();
      final userLoc = const LatLng(
        21.028511,
        105.804817,
      ); // Same as post30MinAgo

      // Test 1km radius
      final within1Km = posts.where((p) {
        if (p.location == null) return false;
        final dist = geoDistance.as(
          LengthUnit.Meter,
          userLoc,
          LatLng(p.location!.lat, p.location!.lng),
        );
        return dist <= 1000;
      }).toList();

      expect(within1Km.length, 2); // post_30m (0m) & post_3h (~560m)
      expect(within1Km.map((p) => p.id), containsAll(['post_30m', 'post_3h']));

      // Test 3km radius
      final within3Km = posts.where((p) {
        if (p.location == null) return false;
        final dist = geoDistance.as(
          LengthUnit.Meter,
          userLoc,
          LatLng(p.location!.lat, p.location!.lng),
        );
        return dist <= 3000;
      }).toList();

      expect(within3Km.length, 3); // post_30m, post_3h, post_12h (~2.7km)
      expect(
        within3Km.map((p) => p.id),
        containsAll(['post_30m', 'post_3h', 'post_12h']),
      );
    });

    test('Combined Filter: 5h AND Tag #tainan', () {
      const targetTag = 'tainan';
      final filtered = posts.where((p) {
        final ts = p.timestamp;
        if (ts == null) return false;
        final diff = DateTime.now().difference(ts);
        if (diff > const Duration(hours: 5)) return false;

        final tags = (p.hashtags ?? []).map(HashtagHelper.toCanonical);
        return tags.contains(targetTag);
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'post_3h');
    });
  });
}
