import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';

import '../theme/app_theme.dart';
import 'loading_widget.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final double? height;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final BorderRadius? borderRadius;
  final TextCapitalization textCapitalization;
  // Trailing logic params
  final bool isLoading;
  final bool showClearButton;
  final VoidCallback? onClear;
  final String? trailingIconAsset;
  final bool isListening;
  final VoidCallback? onVoiceTap;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.height,
    this.onSubmitted,
    this.onChanged,
    this.borderRadius,
    this.textCapitalization = TextCapitalization.none,
    this.isLoading = false,
    this.showClearButton = false,
    this.onClear,
    this.trailingIconAsset,
    this.isListening = false,
    this.onVoiceTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _isFocused = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Container(
        height: widget.maxLines == 1 ? (widget.height ?? 56.h) : widget.height,
        decoration: BoxDecoration(
          color: _isFocused
              ? AppTheme.primaryColor.withOpacity(0.08)
              : AppTheme.inputFillColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
          border: _isFocused
              ? Border.all(color: AppTheme.primaryColor, width: 1)
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: widget.maxLines != 1 ? 12.h : 0,
        ),
        child: Row(
          crossAxisAlignment: widget.maxLines != 1
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(
                widget.prefixIcon,
                color: _isFocused
                    ? AppTheme.primaryColor
                    : AppTheme.subTextColor,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.isPassword && _isObscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                onSubmitted: widget.onSubmitted,
                onChanged: widget.onChanged,
                cursorColor: AppTheme.primaryColor,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.subTextColor,
                  ),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (widget.isLoading)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: LoadingWidget(height: 28.h, width: 28.w),
              )
            else if (widget.showClearButton)
              GestureDetector(
                onTap: widget.onClear,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(
                    IconlyBroken.close_square,
                    size: 20.w,
                    color: _isFocused
                        ? AppTheme.primaryColor
                        : AppTheme.subTextColor,
                  ),
                ),
              )
            else if (widget.trailingIconAsset != null)
              GestureDetector(
                onTap: widget.onVoiceTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: widget.isListening
                      ? _PulsingMicIcon(color: AppTheme.primaryColor)
                      : SvgPicture.asset(
                          widget.trailingIconAsset!,
                          width: 20.w,
                          height: 20.w,
                          colorFilter: ColorFilter.mode(
                            _isFocused
                                ? AppTheme.primaryColor
                                : AppTheme.subTextColor,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
              )
            else if (widget.isPassword)
              IconButton(
                icon: Icon(
                  _isObscure ? IconlyBroken.hide : IconlyBroken.show,
                  color: _isFocused
                      ? AppTheme.primaryColor
                      : AppTheme.subTextColor,
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget icon mic nhấp nháy khi đang lắng nghe giọng nói
class _PulsingMicIcon extends StatefulWidget {
  final Color color;
  const _PulsingMicIcon({required this.color});

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Icon(IconlyBold.voice, size: 20.w, color: widget.color),
    );
  }
}
