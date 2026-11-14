import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Widget hiển thị chấm xanh định vị vị trí hiện tại của người dùng (Pulsing Blue Dot)
class UserLocationMarkerWidget extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const UserLocationMarkerWidget({
    super.key,
    this.size = 56.0,
    this.onTap,
  });

  @override
  State<UserLocationMarkerWidget> createState() =>
      _UserLocationMarkerWidgetState();
}

class _UserLocationMarkerWidgetState extends State<UserLocationMarkerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxRadius = widget.size / 2;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Chùm sáng chỉ hướng phong cách Apple Maps (Directional Beam Cone)
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: const _AppleLocationBeamPainter(
                  color: AppTheme.primaryColor,
                ),
              ),

              // Vòng sóng xanh lan tỏa nhẹ nhàng
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final progress =
                      Curves.easeOut.transform(_pulseController.value);
                  final currentRadius = 9.0 + (maxRadius - 9.0) * progress;
                  final opacity = (1.0 - progress).clamp(0.0, 1.0);

                  return Container(
                    width: currentRadius * 2,
                    height: currentRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(
                        alpha: 0.22 * opacity,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(
                          alpha: 0.45 * opacity,
                        ),
                        width: 1.0,
                      ),
                    ),
                  );
                },
              ),

              // Vòng nền mờ tĩnh bao quanh tâm chấm xanh
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.16),
                ),
              ),

              // Chấm tròn trung tâm có viền trắng chuẩn Apple Maps Puck
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleLocationBeamPainter extends CustomPainter {
  final Color color;

  const _AppleLocationBeamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.32),
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.15, 0.65, 1.0],
      ).createShader(rect);

    // Góc quạt hướng lên phía trước (-125 độ, mở rộng 70 độ như Apple Maps)
    canvas.drawArc(
      rect,
      -2.18,
      1.22,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AppleLocationBeamPainter oldDelegate) =>
      oldDelegate.color != color;
}

