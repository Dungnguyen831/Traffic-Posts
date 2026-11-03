import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/custom_alert.dart';

class EditPostBottomSheet extends StatefulWidget {
  final TrafficPostModel post;
  final Future<void> Function(String newContent) onSave;

  const EditPostBottomSheet({
    super.key,
    required this.post,
    required this.onSave,
  });

  static void show({
    required TrafficPostModel post,
    required Future<void> Function(String newContent) onSave,
  }) {
    Get.bottomSheet(
      EditPostBottomSheet(
        post: post,
        onSave: onSave,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<EditPostBottomSheet> createState() => _EditPostBottomSheetState();
}

class _EditPostBottomSheetState extends State<EditPostBottomSheet> {
  late final TextEditingController _contentController;
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialText = widget.post.content ?? '';
    _contentController = TextEditingController(text: initialText);
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: initialText.length),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final newContent = _contentController.text.trim();
    if (newContent.isEmpty) {
      CustomAlert.showWarning('camera_please_enter_content'.tr);
      return;
    }

    final oldContent = (widget.post.content ?? '').trim();
    if (newContent == oldContent) {
      Get.back();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(newContent);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomKeyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final hashtags = widget.post.hashtags ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomKeyboardInset),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              // Tái sử dụng hiệu ứng Liquid Glass đặc trưng của dự án (SosBottomSheet / SosActiveScreen)
              color: const Color(0xFFECECEC).withValues(alpha: 0.88),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28.r),
                topRight: Radius.circular(28.r),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh kéo (Drag handle)
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Header: Icon + Tiêu đề
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconlyBold.edit,
                            color: AppTheme.primaryColor,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'post_edit_title'.tr,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'post_edit_subtitle'.tr,
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  color: AppTheme.subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // Ô nhập nội dung bài viết với nền kính mờ sáng
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _contentController,
                        focusNode: _focusNode,
                        autofocus: true,
                        minLines: 4,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText: 'camera_content_placeholder'.tr,
                          hintStyle: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.grey[400],
                          ),
                          contentPadding: EdgeInsets.all(16.w),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (hashtags.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: hashtags.map((tag) {
                          final cleanTag = tag.replaceAll('#', '').trim();
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              '#$cleanTag',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    SizedBox(height: 24.h),

                    // Hai nút: Hủy và Lưu thay đổi
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'profile_cancel'.tr,
                            type: ButtonType.secondary,
                            onPressed: _isSaving ? () {} : () => Get.back(),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: 'save_changes'.tr,
                            type: _isSaving
                                ? ButtonType.secondary
                                : ButtonType.primary,
                            isLoading: _isSaving,
                            onPressed: _handleSave,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

