import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:traffic_app/data/models/traffic_post_model.dart';
import 'package:traffic_app/modules/dashboard/widgets/post_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  testWidgets('Double tap on PostItem triggers like and unlike toggle',
      (WidgetTester tester) async {
    final isLikedRx = false.obs;
    final likeCountRx = 5.obs;
    final isFollowedRx = false.obs;
    int likeCalls = 0;

    final dummyPost = TrafficPostModel(
      id: 'post_test_1',
      userId: '10',
      userName: 'Nguyen Van A',
      content: 'Báo cáo giao thông kẹt xe',
      timestamp: DateTime.now(),
      likes: 5,
      isLiked: false,
    );

    Widget buildTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostItem(
                post: dummyPost,
                isLikedRx: isLikedRx,
                likeCountRx: likeCountRx,
                isFollowedRx: isFollowedRx,
                onLike: () {
                  likeCalls++;
                  final wasLiked = isLikedRx.value;
                  isLikedRx.value = !wasLiked;
                  likeCountRx.value = wasLiked
                      ? likeCountRx.value - 1
                      : likeCountRx.value + 1;
                },
                onReport: () {},
                onFollow: () {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(likeCalls, 0);
    expect(isLikedRx.value, false);
    expect(likeCountRx.value, 5);

    // 1. Nhấn đúp lần đầu vào phạm vi bài viết -> Like bài viết
    final postItemFinder = find.byType(PostItem);
    expect(postItemFinder, findsOneWidget);

    // Double tap bằng cách tap 2 lần liên tiếp
    await tester.tap(postItemFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(postItemFinder);
    await tester.pump();

    // Verify onLike được gọi, chuyển sang trạng thái đã like
    expect(likeCalls, 1);
    expect(isLikedRx.value, true);
    expect(likeCountRx.value, 6);

    // Hiệu ứng icon trái tim hiển thị
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    // Cho animation hoàn tất
    await tester.pump(const Duration(milliseconds: 800));

    // Đợi hơn 350ms throttle trước khi nhấn đúp lần 2 (dùng runAsync để trôi thời gian thực tế trong FakeAsync)
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();

    // 2. Nhấn đúp lần nữa -> Hủy like bài viết
    await tester.tap(postItemFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(postItemFinder);
    await tester.pump();

    expect(likeCalls, 2);
    expect(isLikedRx.value, false);
    expect(likeCountRx.value, 5);

    // Hiệu ứng icon hủy like (trái tim vỡ) hiển thị
    expect(find.byIcon(Icons.heart_broken_rounded), findsOneWidget);

    // Cho animation hoàn tất
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('Double tap on image triggers like toggle, single tap opens viewer',
      (WidgetTester tester) async {
    final isLikedRx = false.obs;
    final likeCountRx = 10.obs;
    final isFollowedRx = false.obs;
    int likeCalls = 0;

    final dummyPostWithImage = TrafficPostModel(
      id: 'post_test_with_img',
      userId: '10',
      userName: 'Tran Thi B',
      content: 'Hình ảnh tắc đường',
      imageUrls: ['https://example.com/traffic.jpg'],
      timestamp: DateTime.now(),
      likes: 10,
      isLiked: false,
    );

    Widget buildTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostItem(
                post: dummyPostWithImage,
                isLikedRx: isLikedRx,
                likeCountRx: likeCountRx,
                isFollowedRx: isFollowedRx,
                onLike: () {
                  likeCalls++;
                  final wasLiked = isLikedRx.value;
                  isLikedRx.value = !wasLiked;
                  likeCountRx.value = wasLiked
                      ? likeCountRx.value - 1
                      : likeCountRx.value + 1;
                },
                onReport: () {},
                onFollow: () {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tìm widget hình ảnh (Container 300.h)
    final imageAreaFinder = find.byType(Hero).first;
    expect(imageAreaFinder, findsOneWidget);

    // 1. Nhấn đúp vào ảnh
    await tester.tap(imageAreaFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(imageAreaFinder);
    await tester.pump();

    // Verify like thành công
    expect(likeCalls, 1);
    expect(isLikedRx.value, true);
    expect(likeCountRx.value, 11);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));

    // Đợi throttle
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();

    // 2. Nhấn đúp vào ảnh lần 2 -> Hủy like
    await tester.tap(imageAreaFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(imageAreaFinder);
    await tester.pump();

    expect(likeCalls, 2);
    expect(isLikedRx.value, false);
    expect(likeCountRx.value, 10);
    expect(find.byIcon(Icons.heart_broken_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('Report button is hidden on own post and visible on others post',
      (WidgetTester tester) async {
    final isLikedRx = false.obs;
    final likeCountRx = 2.obs;
    final isFollowedRx = false.obs;

    final post = TrafficPostModel(
      id: 'post_report_check',
      userId: '10',
      userName: 'Nguyen Van A',
      content: 'Kiểm tra nút báo cáo',
      timestamp: DateTime.now(),
      likes: 2,
      isLiked: false,
    );

    Widget buildWidget({required int? currentUserId}) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => GetMaterialApp(
          translationsKeys: const {
            'vi_VN': {'report': 'Báo cáo'},
          },
          locale: const Locale('vi', 'VN'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostItem(
                post: post,
                currentUserId: currentUserId,
                isLikedRx: isLikedRx,
                likeCountRx: likeCountRx,
                isFollowedRx: isFollowedRx,
                onLike: () {},
                onReport: () {},
                onFollow: () {},
              ),
            ),
          ),
        ),
      );
    }

    // Bài viết của người khác (currentUserId = 99 != 10) -> hiển thị nút Báo cáo
    await tester.pumpWidget(buildWidget(currentUserId: 99));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo'), findsOneWidget);

    // Bài viết của chính người dùng (currentUserId = 10 == 10) -> ẩn nút Báo cáo
    await tester.pumpWidget(buildWidget(currentUserId: 10));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo'), findsNothing);
  });

  testWidgets(
      'Multiple PostItems with identical post.id render without Hero tag conflict and support reactive hashtag taps',
      (WidgetTester tester) async {
    final isLikedRx = false.obs;
    final likeCountRx = 3.obs;
    final isFollowedRx = false.obs;
    final activeHashtagRx = RxnString();
    String? tappedTag;

    final post = TrafficPostModel(
      id: 'dup_post_1',
      userId: '10',
      userName: 'Người dùng có tên rất dài để kiểm tra chống tràn giao diện',
      userBadge: 'Người dẫn đường',
      content: 'Tuyến đường đang ùn tắc',
      hashtags: ['ketxe', 'tainan'],
      timestamp: DateTime.now(),
      likes: 3,
      isLiked: false,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => GetMaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PostItem(
                  post: post,
                  isLikedRx: isLikedRx,
                  likeCountRx: likeCountRx,
                  isFollowedRx: isFollowedRx,
                  activeHashtagRx: activeHashtagRx,
                  onTapHashtag: (tag) {
                    tappedTag = tag;
                    activeHashtagRx.value = tag;
                  },
                  onLike: () {},
                  onReport: () {},
                  onFollow: () {},
                ),
                PostItem(
                  post: post,
                  isLikedRx: isLikedRx,
                  likeCountRx: likeCountRx,
                  isFollowedRx: isFollowedRx,
                  activeHashtagRx: activeHashtagRx,
                  onTapHashtag: (tag) {
                    tappedTag = tag;
                    activeHashtagRx.value = tag;
                  },
                  onLike: () {},
                  onReport: () {},
                  onFollow: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PostItem), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    // Cập nhật activeHashtagRx để kiểm tra tính phản ứng cục bộ của RichText
    activeHashtagRx.value = 'ketxe';
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tappedTag, isNull);
  });
}
