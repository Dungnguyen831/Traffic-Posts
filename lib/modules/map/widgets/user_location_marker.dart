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

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vòng sóng xanh lan tỏa nhẹ nhàng
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final progress = Curves.easeOut.transform(_pulseController.value);
                final currentRadius = 9.0 + (maxRadius - 9.0) * progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);

                return Container(
                  width: currentRadius * 2,
                  height: currentRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(
                      alpha: 0.28 * opacity,
                    ),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(
                        alpha: 0.55 * opacity,
                      ),
                      width: 1.2,
                    ),
                  ),
                );
              },
            ),

            // Vòng nền mờ tĩnh bao quanh tâm chấm xanh
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.18),
              ),
            ),

            // Chấm tròn trung tâm có viền trắng nổi bật trên cả nền Mặc định và Vệ tinh
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                border: Border.all(
                  color: Colors.white,
                  width: 3.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

