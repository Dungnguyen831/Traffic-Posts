import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../../data/models/sos_model.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../../theme/app_theme.dart';
import '../controllers/sos_stream_controller.dart';

class SosStreamView extends GetView<SosStreamController> {
  const SosStreamView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'SOS Alerts',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        centerTitle: false,
        actions: [
          Obx(() {
            final status = controller.sosService.connectionStatus.value;
            return Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: _ConnectionBadge(status: status),
            );
          }),
        ],
      ),
      body: Obx(() {
        final status = controller.sosService.connectionStatus.value;
        final list = controller.sosService.sosList;

        return Column(
          children: [
            _StatusBanner(
              status: status,
              error: controller.sosService.lastError.value,
            ),
            Expanded(
              child: list.isEmpty
                  ? _EmptyState(status: status)
                  : RefreshIndicator(
                      color: AppTheme.primaryColor,
                      onRefresh: () async {
                        controller.sosService.connect();
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 10.h),
                        itemBuilder: (_, i) => _SosCard(sos: list[i]),
                      ),
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        final status = controller.sosService.connectionStatus.value;
        final isConnected = status == SosConnectionStatus.connected;
        return FloatingActionButton.small(
          backgroundColor: isConnected ? Colors.green : AppTheme.primaryColor,
          onPressed: () {
            if (status == SosConnectionStatus.connected) {
              controller.sosService.disconnect();
            } else {
              controller.sosService.connect();
            }
          },
          tooltip: isConnected ? 'Ngắt kết nối' : 'Kết nối lại',
          child: Icon(
            isConnected ? Icons.wifi_off : Icons.wifi,
            color: Colors.white,
            size: 18.r,
          ),
        );
      }),
    );
  }
}

// ─── Connection badge ──────────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status});
  final SosConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    bool showPulse;

    switch (status) {
      case SosConnectionStatus.connected:
        color = Colors.green;
        label = 'Live';
        showPulse = true;
        break;
      case SosConnectionStatus.connecting:
        color = Colors.orange;
        label = 'Đang kết nối';
        showPulse = false;
        break;
      case SosConnectionStatus.reconnecting:
        color = Colors.orange;
        label = 'Reconnect...';
        showPulse = false;
        break;
      case SosConnectionStatus.noNetwork:
        color = Colors.grey;
        label = 'Mất mạng';
        showPulse = false;
        break;
      case SosConnectionStatus.error:
        color = Colors.red;
        label = 'Lỗi';
        showPulse = false;
        break;
      case SosConnectionStatus.disconnected:
        color = Colors.grey;
        label = 'Offline';
        showPulse = false;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color, pulse: showPulse),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: widget.pulse ? _anim.value : 1.0,
        child: Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Status banner ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.error});
  final SosConnectionStatus status;
  final String error;

  @override
  Widget build(BuildContext context) {
    String? msg;
    Color bg;
    IconData icon;

    switch (status) {
      case SosConnectionStatus.noNetwork:
        msg = 'Không có kết nối mạng. Sẽ tự động kết nối lại khi có mạng.';
        bg = Colors.orange.shade50;
        icon = Icons.wifi_off;
        break;
      case SosConnectionStatus.reconnecting:
        msg = 'Đang thử kết nối lại...';
        bg = Colors.blue.shade50;
        icon = Icons.sync;
        break;
      case SosConnectionStatus.connecting:
        msg = 'Đang kết nối tới server...';
        bg = Colors.blue.shade50;
        icon = Icons.sync;
        break;
      case SosConnectionStatus.error:
        msg = error.isNotEmpty
            ? error
            : 'Kết nối thất bại. Kéo xuống để thử lại.';
        bg = Colors.red.shade50;
        icon = IconlyBroken.danger;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: Colors.black54),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 12.sp, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final SosConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == SosConnectionStatus.connecting ||
        status == SosConnectionStatus.reconnecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32.r,
              height: 32.r,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Đang kết nối...',
              style: TextStyle(fontSize: 14.sp, color: AppTheme.subTextColor),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconlyBroken.notification,
            size: 48.r,
            color: AppTheme.dividerColor,
          ),
          SizedBox(height: 12.h),
          Text(
            status == SosConnectionStatus.connected
                ? 'Chưa có cảnh báo SOS nào'
                : 'Chưa kết nối',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.subTextColor),
          ),
        ],
      ),
    );
  }
}

// ─── SOS Card ──────────────────────────────────────────────────────────────

class _SosCard extends StatelessWidget {
  const _SosCard({required this.sos});
  final SosResponseDTO sos;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(sos.status);
    final timeStr = sos.timestamp != null
        ? DateFormat('HH:mm dd/MM/yyyy').format(sos.timestamp!.toLocal())
        : '--';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  sos.status?.toUpperCase() ?? 'UNKNOWN',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                IconlyBroken.time_circle,
                size: 12.r,
                color: AppTheme.subTextColor,
              ),
              SizedBox(width: 3.w),
              Text(
                timeStr,
                style: TextStyle(fontSize: 11.sp, color: AppTheme.subTextColor),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (sos.phoneNumber != null) ...[
            _InfoRow(
              icon: IconlyBroken.call,
              text: sos.phoneNumber!,
              iconColor: Colors.green,
            ),
            SizedBox(height: 6.h),
          ],
          if (sos.address != null) ...[
            _InfoRow(
              icon: IconlyBroken.location,
              text: sos.address!,
              iconColor: Colors.red,
            ),
            SizedBox(height: 6.h),
          ],
          if (sos.latitude != null && sos.longitude != null) ...[
            _InfoRow(
              icon: IconlyBold.location,
              text:
                  '${sos.latitude!.toStringAsFixed(5)}, ${sos.longitude!.toStringAsFixed(5)}',
              iconColor: AppTheme.primaryColor,
            ),
            SizedBox(height: 6.h),
          ],
          if (sos.note != null && sos.note!.isNotEmpty) ...[
            Divider(height: 12.h, color: AppTheme.dividerColor),
            _InfoRow(
              icon: IconlyBroken.document,
              text: sos.note!,
              iconColor: AppTheme.subTextColor,
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
  });
  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.r, color: iconColor),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: AppTheme.textColor),
          ),
        ),
      ],
    );
  }
}
