import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Component hộp hiệu ứng kính lỏng (Liquid Glass) đồng bộ hoàn toàn với thanh điều hướng LiquidGlassBottomBar.
/// Hỗ trợ khúc xạ ánh sáng (refraction), bóng mờ (blur), đường viền nổi (border highlight) và gradient trong suốt.
class AppGlassContainer extends StatelessWidget {
  const AppGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.customShape,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.glassColor,
    this.borderSide,
    this.gradientColors,
    this.boxShadow,
    this.blur = 8.0,
    this.refractiveIndex = 1.12,
    this.thickness = 18.0,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final double borderRadius;
  final LiquidShape? customShape;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? glassColor;
  final BorderSide? borderSide;
  final List<Color>? gradientColors;
  final List<BoxShadow>? boxShadow;
  final double blur;
  final double refractiveIndex;
  final double thickness;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderSide =
        borderSide ??
        BorderSide(color: Colors.white.withValues(alpha: 0.65), width: 0.9);

    final effectiveGradientColors =
        gradientColors ??
        [
          Colors.white.withValues(alpha: 0.78),
          Colors.white.withValues(alpha: 0.62),
        ];

    final effectiveShadow =
        boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

    final shape =
        customShape ??
        LiquidRoundedSuperellipse(
          borderRadius: borderRadius,
          side: effectiveBorderSide,
        );

    final glassSettings = LiquidGlassSettings(
      refractiveIndex: refractiveIndex,
      thickness: thickness,
      blur: blur,
      saturation: 1.1,
      lightIntensity: 1.1,
      ambientStrength: 0.5,
      lightAngle: math.pi / 4,
      glassColor: glassColor ?? Colors.white.withValues(alpha: 0.55),
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadow,
      ),
      child: LiquidGlass.withOwnLayer(
        clipBehavior: clipBehavior,
        settings: glassSettings,
        shape: shape,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: effectiveGradientColors,
            ),
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}
