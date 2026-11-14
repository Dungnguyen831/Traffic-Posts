import 'package:get/get.dart';

/// Tiện ích quản lý và chuẩn hóa Hashtag đa ngôn ngữ (VI / EN).
/// Lưu trữ đồng nhất Canonical ID ('ketxe', 'tainan'...) dưới Backend
/// nhưng hiển thị nhãn và hashtag tùy biến theo Locale người dùng.
class HashtagHelper {
  static const Map<
    String,
    ({String vi, String en, String labelKey, List<String> aliases})
  >
  _tags = {
    'ketxe': (
      vi: 'ketxe',
      en: 'trafficjam',
      labelKey: 'hashtag_label_ketxe',
      aliases: [
        'ket xe',
        'kẹt xe',
        'traffic jam',
        'trafficjam',
        'congested',
        'congestion',
        'jam',
      ],
    ),
    'tainan': (
      vi: 'tainan',
      en: 'accident',
      labelKey: 'hashtag_label_tainan',
      aliases: ['tai nan', 'tai nạn', 'accident', 'crash', 'collision'],
    ),
    'ngaplutnuoc': (
      vi: 'ngaplutnuoc',
      en: 'flooding',
      labelKey: 'hashtag_label_ngaplutnuoc',
      aliases: [
        'ngap nuoc',
        'ngập nước',
        'ngap lut',
        'ngập lụt',
        'flood',
        'flooding',
      ],
    ),
    'baocaotainan': (
      vi: 'baocaotainan',
      en: 'alert',
      labelKey: 'hashtag_label_baocaotainan',
      aliases: [
        'canh bao',
        'cảnh báo',
        'bao cao',
        'báo cáo',
        'alert',
        'warning',
        'hazard',
      ],
    ),
    'giaothong': (
      vi: 'giaothong',
      en: 'traffic',
      labelKey: 'hashtag_label_giaothong',
      aliases: ['giao thong', 'giao thông', 'traffic'],
    ),
    'sos': (
      vi: 'sos',
      en: 'sos',
      labelKey: 'sos_sheet_title',
      aliases: ['sos', 'cuu ho', 'cứu hộ', 'emergency', 'rescue'],
    ),
  };

  /// Chuyển mọi tag (kể cả tiếng Anh '#trafficjam', '#accident' hoặc có dấu cách 'tai nan') về canonical ID chuẩn
  static String toCanonical(String rawTag) {
    final clean = rawTag.toLowerCase().replaceAll('#', '').trim();
    for (final entry in _tags.entries) {
      if (entry.key == clean ||
          entry.value.vi == clean ||
          entry.value.en == clean ||
          entry.value.aliases.contains(clean)) {
        return entry.key;
      }
    }
    return clean;
  }

  /// Trả về nhãn đọc được (Dành cho nút chọn Camera - Phương án B): VD 'Traffic jam' hoặc 'Kẹt xe'
  static String getLabel(String rawTag) {
    final canonical = toCanonical(rawTag);
    final info = _tags[canonical];
    if (info != null) {
      return info.labelKey.tr;
    }
    return rawTag;
  }

  /// Trả về chuỗi hashtag theo ngôn ngữ hiện tại (VD: '#trafficjam' hoặc '#ketxe')
  static String format(String rawTag, {bool withHash = true}) {
    final canonical = toCanonical(rawTag);
    final info = _tags[canonical];
    final isEn = Get.locale?.languageCode == 'en';
    final slug = info != null ? (isEn ? info.en : info.vi) : canonical;
    return withHash ? '#$slug' : slug;
  }

  /// Kiểm tra bài viết có chứa hashtag khớp với từ khóa tìm kiếm (Anh / Việt) hay không
  static bool matchesKeyword(List<String>? hashtags, String keyword) {
    if (hashtags == null || hashtags.isEmpty) return false;
    final kw = keyword.toLowerCase().replaceAll('#', '').trim();
    if (kw.isEmpty) return false;

    for (final raw in hashtags) {
      final canonical = toCanonical(raw);
      final info = _tags[canonical];
      if (info != null) {
        if (canonical.contains(kw) ||
            info.vi.contains(kw) ||
            info.en.contains(kw) ||
            info.aliases.any((a) => a.contains(kw) || kw.contains(a))) {
          return true;
        }
      } else {
        if (raw.toLowerCase().contains(kw)) return true;
      }
    }
    return false;
  }
}
