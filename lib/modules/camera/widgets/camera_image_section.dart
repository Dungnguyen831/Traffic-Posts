import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/loading_widget.dart';
import '../controllers/camera_controller.dart';

class CameraImageSection extends GetView<CameraController> {
  const CameraImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasImg = controller.hasImage.value && controller.imageFile != null;
      final status = controller.moderationStatus.value;

      return GestureDetector(
        onTap: () {
          if (!hasImg || status == ImageModerationStatus.invalid) {
            controller.pickImageFromGallery();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 370.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32.r),
            border: hasImg ? _borderForStatus(status) : null,
            boxShadow: hasImg ? _shadowForStatus(status) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: hasImg
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        controller.imageFile!,
                        fit: BoxFit.cover,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _buildModerationOverlay(status),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyBroken.camera,
                          size: 64.sp,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'camera_capture_or_pick'.tr,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Border? _borderForStatus(ImageModerationStatus status) {
    switch (status) {
      case ImageModerationStatus.checking:
        return Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.7),
          width: 2.w,
        );
      case ImageModerationStatus.valid:
        return Border.all(
          color: AppTheme.successColor,
          width: 2.w,
        );
      case ImageModerationStatus.invalid:
        return Border.all(
          color: AppTheme.errorColor,
          width: 2.5.w,
        );
      case ImageModerationStatus.error:
        return Border.all(
          color: AppTheme.warningColor,
          width: 2.w,
        );
      case ImageModerationStatus.none:
        return null;
    }
  }

  List<BoxShadow>? _shadowForStatus(ImageModerationStatus status) {
    switch (status) {
      case ImageModerationStatus.checking:
        return [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.18),
            blurRadius: 16.r,
            offset: const Offset(0, 6),
          ),
        ];
      case ImageModerationStatus.valid:
        return [
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.16),
            blurRadius: 16.r,
            offset: const Offset(0, 6),
          ),
        ];
      case ImageModerationStatus.invalid:
        return [
          BoxShadow(
            color: AppTheme.errorColor.withValues(alpha: 0.2),
            blurRadius: 16.r,
            offset: const Offset(0, 6),
          ),
        ];
      default:
        return null;
    }
  }

  Widget _buildModerationOverlay(ImageModerationStatus status) {
    switch (status) {
      case ImageModerationStatus.checking:
        return const _AiScanningOverlay(key: ValueKey('checking'));
      case ImageModerationStatus.valid:
        return Align(
          key: const ValueKey('valid'),
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: AppTheme.successBgColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconlyBold.shield_done,
                    color: AppTheme.successColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'camera_image_valid_badge'.tr,
                    style: TextStyle(
                      color: AppTheme.successAlertTextColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case ImageModerationStatus.invalid:
        return Container(
          key: const ValueKey('invalid'),
          color: Colors.black.withValues(alpha: 0.58),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20.r,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconlyBold.danger,
                      color: AppTheme.errorColor,
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'camera_image_invalid_title'.tr,
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    controller.moderationMessage.value.isNotEmpty
                        ? controller.moderationMessage.value
                        : 'camera_image_invalid_message'.tr,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 12.5.sp,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: controller.pickImageFromGallery,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBgColor,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconlyBroken.image,
                            size: 16.sp,
                            color: AppTheme.errorColor,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'camera_reselect_image'.tr,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case ImageModerationStatus.error:
        return Container(
          key: const ValueKey('error'),
          color: Colors.black.withValues(alpha: 0.52),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20.r,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: const BoxDecoration(
                      color: AppTheme.warningBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconlyBroken.danger,
                      color: AppTheme.warningColor,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'camera_image_moderation_error'.tr,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: controller.validateSelectedImage,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBgColor,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Text(
                        'discovery_retry'.tr,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case ImageModerationStatus.none:
        return const SizedBox.shrink(key: ValueKey('none'));
    }
  }
}

class _AiScanningOverlay extends StatefulWidget {
  const _AiScanningOverlay({super.key});

  @override
  State<_AiScanningOverlay> createState() => _AiScanningOverlayState();
}

class _AiScanningOverlayState extends State<_AiScanningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Lớp nền tối mờ
        Container(color: Colors.black.withValues(alpha: 0.42)),

        // Hiệu ứng Shimmer phủ nhẹ trên bề mặt ảnh
        Shimmer.fromColors(
          baseColor: AppTheme.primaryColor.withValues(alpha: 0.08),
          highlightColor: AppTheme.primaryLightColor.withValues(alpha: 0.28),
          period: const Duration(milliseconds: 1400),
          child: Container(color: Colors.white),
        ),

        // Thanh quét AI di chuyển dọc bức ảnh
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return Align(
              alignment: Alignment(0, _scanController.value * 2 - 1),
              child: child,
            );
          },
          child: Container(
            height: 68.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryLightColor.withValues(alpha: 0.0),
                  AppTheme.primaryLightColor.withValues(alpha: 0.32),
                  AppTheme.primaryColor.withValues(alpha: 0.85),
                  AppTheme.primaryLightColor.withValues(alpha: 0.32),
                  AppTheme.primaryLightColor.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // Card hiển thị Lottie Loading & Trạng thái kiểm duyệt ở trung tâm ảnh
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20.r,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(height: 56.h),
                SizedBox(height: 6.h),
                Text(
                  'camera_moderating_image'.tr,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
