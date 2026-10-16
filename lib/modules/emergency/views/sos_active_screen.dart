import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../controllers/emergency_controller.dart';

/// 1. Widget Marker Radar sóng tỏa trên tọa độ điểm đang phát tín hiệu
class SosRadarMarkerWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final double size;

  const SosRadarMarkerWidget({
    super.key,
    this.onTap,
    this.size = 140.0,
  });

  @override
  State<SosRadarMarkerWidget> createState() => _SosRadarMarkerWidgetState();
}

class _SosRadarMarkerWidgetState extends State<SosRadarMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildRippleRing(double delay, double maxRadius) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = (_animController.value + delay) % 1.0;
        final currentRadius = 18.0 + (maxRadius - 18.0) * progress;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);

        return Container(
          width: currentRadius * 2,
          height: currentRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.errorColor.withOpacity(0.25 * opacity),
            border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.75 * opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxRadius = widget.size / 2;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 3 vòng sóng lan tỏa gối đầu nhau
            _buildRippleRing(0.0, maxRadius),
            _buildRippleRing(0.33, maxRadius),
            _buildRippleRing(0.66, maxRadius),

            // Tâm icon SOS phát sáng
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFF3B30),
                    Color(0xFFCC1F1A),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Widget Dialog/Banner ghim trên đỉnh màn hình (Hiển thị dạng trong suốt Liquid Glass với icon dấu X đỏ đơn giản)
class SosTopBannerWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const SosTopBannerWidget({super.key, this.onTap});

  @override
  State<SosTopBannerWidget> createState() => _SosTopBannerWidgetState();
}

class _SosTopBannerWidgetState extends State<SosTopBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergencyCtrl = Get.find<EmergencyController>();

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onTap ?? () => emergencyCtrl.isSheetMinimized.value = false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Đèn nhấp nháy báo SOS
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.errorColor.withOpacity(
                            0.15 + 0.25 * _pulseController.value,
                          ),
                          border: Border.all(
                            color: AppTheme.errorColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.emergency,
                          color: AppTheme.errorColor,
                          size: 20.sp,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 12.w),

                  // Nội dung cảnh báo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đang phát tín hiệu cứu hộ',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Text(
                              'Chạm để xem chi tiết',
                              style: TextStyle(
                                color: AppTheme.subTextColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              IconlyLight.arrow_up_2,
                              color: AppTheme.subTextColor,
                              size: 11.sp,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Nút đóng SOS: Icon dấu X đơn giản màu đỏ
                  Obx(
                    () => InkWell(
                      onTap: emergencyCtrl.isLoading.value
                          ? null
                          : () => emergencyCtrl.closeActiveSos(),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.errorColor.withOpacity(0.12),
                        ),
                        child: emergencyCtrl.isLoading.value
                            ? const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.close_rounded,
                                color: AppTheme.errorColor,
                                size: 20.sp,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3. Widget Hiển thị SOS ở phía dưới màn hình (Hỗ trợ bấm giữ kéo lên/xuống linh hoạt, màu trong suốt liquid, nút nguồn đỏ tắt SOS)
class SosActiveBottomView extends StatefulWidget {
  const SosActiveBottomView({super.key});

  @override
  State<SosActiveBottomView> createState() => _SosActiveBottomViewState();
}

class _SosActiveBottomViewState extends State<SosActiveBottomView>
    with SingleTickerProviderStateMixin {
  double _dragOffsetY = 0.0;
  late AnimationController _springController;
  Animation<double>? _springAnim;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _springController.addListener(() {
      if (_springAnim != null) {
        setState(() {
          _dragOffsetY = _springAnim!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _springController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffsetY = _dragOffsetY + details.delta.dy;
      // Damping khi cố kéo ngược lên trên vượt quá vị trí ban đầu
      if (_dragOffsetY < 0) {
        _dragOffsetY = _dragOffsetY * 0.2;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final emergencyCtrl = Get.find<EmergencyController>();
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffsetY > 75 || velocity > 250) {
      emergencyCtrl.isSheetMinimized.value = true;
      setState(() {
        _dragOffsetY = 0.0;
      });
    } else {
      // Bật ngược trở lại vị trí cũ mượt mà bằng lò xo
      _springAnim = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyCtrl = Get.find<EmergencyController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      // Bấm giữ và kéo linh hoạt lên / xuống theo tay người dùng
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),
            topRight: Radius.circular(32.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // Màu trong suốt liquid đặc trưng của dự án (tương đồng LiquidGlassBottomBar)
                color: const Color(0xFFECECEC).withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32.r),
                  topRight: Radius.circular(32.r),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomInset + 18.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thanh Handle Bar kéo vuốt
                  Container(
                    width: 46.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Nút bấm gợi ý vuốt xuống
                  InkWell(
                    onTap: () => emergencyCtrl.isSheetMinimized.value = true,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconlyLight.arrow_down_2,
                            size: 14.sp,
                            color: AppTheme.subTextColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Vuốt xuống để xem bản đồ',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Ghi chú chi tiết sự cố (Khối trong suốt liquid viền trắng thanh lịch)
                  Obx(() {
                    final note = emergencyCtrl.activeSosNote.value.trim();

                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 20.h),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16.sp,
                                color: AppTheme.errorColor,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Chi tiết sự cố:',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            note.isNotEmpty ? note : 'Đang yêu cầu cứu hộ khẩn cấp',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Nút nguồn màu đỏ để tắt phát tín hiệu
                  Obx(
                    () => GestureDetector(
                      onTap: emergencyCtrl.isLoading.value
                          ? null
                          : () => emergencyCtrl.closeActiveSos(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 66.w,
                            height: 66.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF3B30),
                                  Color(0xFFD32F2F),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3B30).withOpacity(0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: emergencyCtrl.isLoading.value
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.power_settings_new_rounded,
                                      color: Colors.white,
                                      size: 34.sp,
                                    ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Tắt phát tín hiệu',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

/// 4. Màn hình SOS Active (Giữ lại để tương thích ngược nếu cần)
class SosActiveScreen extends StatelessWidget {
  const SosActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SosActiveBottomView(),
        ),
      ),
    );
  }
}