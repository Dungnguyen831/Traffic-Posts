import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';

import 'loading_widget.dart';

/// Trình xem ảnh toàn màn hình hỗ trợ:
/// - Pinch-to-zoom (2 ngón tay phóng to từ 1x đến 5x) và kéo (pan) quan sát chi tiết
/// - Chạm đúp (double-tap) để phóng to 2.5x vào đúng điểm chạm hoặc thu nhỏ về 1x
/// - Lướt ngang nhiều ảnh (PageView) khi ở mức zoom mặc định
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    if (imageUrls.isEmpty) return Future.value();
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenImageViewer(
              imageUrls: imageUrls,
              initialIndex: initialIndex,
              heroTagPrefix: heroTagPrefix,
            ),
          );
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isCurrentPageZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Chạm vào khoảng trống nền đen để đóng nhanh khi chưa zoom
          GestureDetector(
            onTap: () {
              if (!_isCurrentPageZoomed) {
                Navigator.of(context).pop();
              }
            },
            child: Container(color: Colors.transparent),
          ),

          // Khu vực hiển thị ảnh có thể zoom
          PageView.builder(
            controller: _pageController,
            physics: _isCurrentPageZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: total,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isCurrentPageZoomed = false;
              });
            },
            itemBuilder: (context, index) {
              final url = widget.imageUrls[index];
              final heroTag = widget.heroTagPrefix != null
                  ? '${widget.heroTagPrefix}_$index'
                  : null;

              return _ZoomableImagePage(
                imageUrl: url,
                heroTag: heroTag,
                onZoomStateChanged: (isZoomed) {
                  if (_isCurrentPageZoomed != isZoomed && mounted) {
                    setState(() {
                      _isCurrentPageZoomed = isZoomed;
                    });
                  }
                },
              );
            },
          ),

          // Thanh công cụ phía trên: Chỉ số ảnh + Hướng dẫn + Nút đóng
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (total > 1)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / $total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pinch_rounded,
                              color: Colors.white70,
                              size: 15.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'image_viewer_zoom_hint'.tr,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImagePage extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final ValueChanged<bool> onZoomStateChanged;

  const _ZoomableImagePage({
    required this.imageUrl,
    this.heroTag,
    required this.onZoomStateChanged,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });

    _transformationController.addListener(_onMatrixChanged);
  }

  void _onMatrixChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    widget.onZoomStateChanged(scale > 1.05);
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final Matrix4 endMatrix;

    if (currentScale > 1.05) {
      // Đang zoom -> Thu về 1x
      endMatrix = Matrix4.identity();
    } else {
      // Phóng to 2.5x vào đúng vị trí chạm đúp
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const targetScale = 2.6;
      endMatrix = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (targetScale - 1),
          -position.dy * (targetScale - 1),
          0.0,
          1.0,
        )
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onMatrixChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(child: LoadingWidget()),
      errorWidget: (context, url, error) => Center(
        child: Icon(
          IconlyBroken.image_2,
          size: 56.w,
          color: Colors.white54,
        ),
      ),
    );

    if (widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        clipBehavior: Clip.none,
        child: Center(
          child: imageWidget,
        ),
      ),
    );
  }
}

