import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../data/models/fine_record_model.dart';
import '../../../../theme/app_theme.dart';

class FineResultList extends StatelessWidget {
  const FineResultList({required this.records, super.key});
  final List<FineRecord> records;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        MediaQuery.of(context).viewPadding.bottom + 80.h,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (_, index) => FineCard(
        key: ValueKey(records[index].violationCode.isNotEmpty
            ? '${records[index].violationCode}_$index'
            : '$index'),
        record: records[index],
        index: index,
      ),
    );
  }
}

class FineCard extends StatefulWidget {
  const FineCard({required this.record, required this.index, super.key});
  final FineRecord record;
  final int index;

  @override
  State<FineCard> createState() => _FineCardState();
}

class _FineCardState extends State<FineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isPaid = record.isPaid;
    final accentColor = isPaid ? AppTheme.successColor : AppTheme.errorColor;
    final statusBgColor =
        isPaid ? AppTheme.successBgColor : AppTheme.errorBgColor;

    final displayIndex = record.index > 0 ? record.index : widget.index + 1;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withValues(alpha: 0.04),
            offset: const Offset(0, 3),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // Nội dung chính của Card
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Số thứ tự + Mã lỗi + Trạng thái
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${'discovery_violation'.tr} #$displayIndex',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (record.violationCode.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBgColor,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            record.violationCode,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          record.status.isEmpty
                              ? 'discovery_status_unknown'.tr
                              : record.status,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Hành vi vi phạm (Mục quan trọng nhất - luôn hiện)
                  Text(
                    record.cleanedViolationTitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Thời gian vi phạm (Luôn hiện)
                  if (record.occurredAt.isNotEmpty)
                    _CompactInfoRow(
                      icon: IconlyBroken.time_circle,
                      iconColor: AppTheme.primaryColor,
                      text: record.formattedOccurredAt,
                    ),

                  // Địa điểm vi phạm (Luôn hiện)
                  if (record.location.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    _CompactInfoRow(
                      icon: IconlyBroken.location,
                      iconColor: AppTheme.errorColor,
                      text: record.location,
                    ),
                  ],

                  SizedBox(height: 12.h),

                  // Nút bấm mở rộng / thu gọn
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppTheme.backgroundColor
                            : AppTheme.primaryBgColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isExpanded
                                ? 'discovery_collapse_details'.tr
                                : 'discovery_view_details'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              IconlyLight.arrow_down_2,
                              size: 14.r,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // PHẦN CHI TIẾT (Dùng ClipRect + AnimatedSize ngăn chặn triệt để RenderFlex overflow)
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _isExpanded
                          ? Padding(
                              padding: EdgeInsets.only(top: 14.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: AppTheme.dividerColor,
                                  ),
                                  SizedBox(height: 12.h),

                                  // Mức phạt & Căn cứ quy định
                                  if (record.penalty.isNotEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningBgColor
                                            .withValues(alpha: 0.7),
                                        borderRadius:
                                            BorderRadius.circular(14.r),
                                        border: Border.all(
                                          color: AppTheme.warningColor
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                IconlyBold.document,
                                                size: 15.r,
                                                color: AppTheme.warningColor,
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                'discovery_field_penalty'.tr,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color:
                                                      AppTheme.warningColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6.h),
                                          Text(
                                            record.penalty,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppTheme.textColor,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                  ],

                                  // Đơn vị phát hiện vi phạm
                                  if (record.detectedBy.isNotEmpty) ...[
                                    _DetailItem(
                                      icon: IconlyBroken.shield_done,
                                      iconColor: AppTheme.primaryColor,
                                      label: 'discovery_field_unit'.tr,
                                      value: record.detectedBy,
                                    ),
                                    SizedBox(height: 12.h),
                                  ],

                                  // Nơi giải quyết vụ việc
                                  if (record.resolutionUnits.isNotEmpty)
                                    _ResolutionUnitsSection(
                                      units: record.resolutionUnits,
                                    ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),

            // Viền màu accent tuyệt đối bên trái (Thay thế hoàn toàn IntrinsicHeight)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4.5.w,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(icon, size: 14.r, color: iconColor),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15.r, color: iconColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResolutionUnitsSection extends StatelessWidget {
  const _ResolutionUnitsSection({required this.units});
  final List<ResolutionUnit> units;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryBgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconlyBold.location,
                size: 15.r,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6.w),
              Text(
                'discovery_field_resolve_location'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...units.asMap().entries.map((entry) {
            final idx = entry.key;
            final unit = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: idx < units.length - 1 ? 8.h : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${idx + 1}. ${unit.name}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                      height: 1.35,
                    ),
                  ),
                  if (unit.address.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      unit.address,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.subTextColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (unit.phone != null && unit.phone!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'SĐT: ${unit.phone}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
