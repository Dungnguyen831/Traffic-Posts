import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

enum DialogType { success, error, warning, info }

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  final DialogType type;
  final String? cancelText;
  final VoidCallback? onCancel;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
    this.type = DialogType.info,
    this.cancelText,
    this.onCancel,
  });

  Color get _color {
    switch (type) {
      case DialogType.success:
        return AppTheme.successColor;
      case DialogType.error:
        return AppTheme.errorColor;
      case DialogType.warning:
        return AppTheme.warningColor;
      case DialogType.info:
        return AppTheme.primaryColor;
    }
  }

  List<Color> get _gradientColors {
    switch (type) {
      case DialogType.success:
        return [AppTheme.successColor, AppTheme.successLightColor];
      case DialogType.error:
        return [AppTheme.errorColor, AppTheme.errorLightColor];
      case DialogType.warning:
        return [AppTheme.warningColor, AppTheme.warningLightColor];
      case DialogType.info:
        return [AppTheme.primaryColor, AppTheme.primaryLightColor];
    }
  }

  Color get _dotColor {
    switch (type) {
      case DialogType.success:
        return AppTheme.successDotColor;
      case DialogType.error:
        return AppTheme.errorDotColor;
      case DialogType.warning:
        return AppTheme.warningDotColor;
      case DialogType.info:
        return AppTheme.primaryDotColor;
    }
  }

  Color get _cancelBgColor {
    switch (type) {
      case DialogType.success:
        return AppTheme.successBgColor;
      case DialogType.error:
        return AppTheme.errorBgColor;
      case DialogType.warning:
        return AppTheme.warningBgColor;
      case DialogType.info:
        return AppTheme.primaryBgColor;
    }
  }

  IconData get _icon {
    switch (type) {
      case DialogType.success:
        return IconlyBold.tick_square;
      case DialogType.error:
        return IconlyBold.close_square;
      case DialogType.warning:
        return IconlyBold.danger;
      case DialogType.info:
        return IconlyBold.info_square;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(32.w, 40.h, 32.w, 32.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header with decorative dots
            SizedBox(
              width: 186.w,
              height: 180.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main gradient circle
                  Container(
                    width: 141.w,
                    height: 141.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: _gradientColors,
                      ),
                    ),
                    child: Icon(_icon, color: Colors.white, size: 58.sp),
                  ),
                  // Decorative dots (match Figma positions)
                  Positioned(top: 20, right: 0, child: _dot(15.w, _dotColor)),
                  Positioned(top: 0, left: 10, child: _dot(20.w, _dotColor)),
                  Positioned(bottom: 0, left: 5, child: _dot(10.w, _dotColor)),
                  Positioned(bottom: 3, right: 2, child: _dot(5.w, _dotColor)),
                  Positioned(top: 2, right: 82, child: _dot(5.w, _dotColor)),
                  Positioned(bottom: 27, left: 59, child: _dot(7.w, _dotColor)),
                  Positioned(
                    bottom: 10,
                    right: 59,
                    child: _dot(2.w, _dotColor),
                  ),
                  Positioned(top: 108, right: 2, child: _dot(5.w, _dotColor)),
                  Positioned(top: 74, left: 0, child: _dot(2.w, _dotColor)),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppTheme.textColor,
                height: 1.4,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),

            // Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  text: buttonText,
                  color: _color,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPressed?.call();
                  },
                ),
                if (cancelText != null) ...[
                  SizedBox(height: 12.h),
                  PrimaryButton(
                    text: cancelText!,
                    color: _cancelBgColor,
                    textColor: _color,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  static void show({
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    DialogType type = DialogType.info,
  }) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: onPressed,
          type: type,
        ),
      );
    }
  }

  static void showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    DialogType type = DialogType.info,
  }) {
    showDialog(
      context: context,
      builder: (_) => CustomDialog(
        title: title,
        message: message,
        buttonText: confirmText ?? 'confirm'.tr,
        cancelText: cancelText ?? 'cancel'.tr,
        onPressed: onConfirm,
        onCancel: onCancel,
        type: type,
      ),
    );
  }
}
