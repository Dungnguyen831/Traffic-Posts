import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dialog.dart';
import 'typing_indicators.dart';

class AiMessageBubble extends StatelessWidget {
  final String text;
  final DateTime? timestamp;
  final bool isStreaming;
  final bool isError;

  static MarkdownStyleSheet? _cachedStyleSheet;

  static MarkdownStyleSheet _getStyleSheet() {
    return _cachedStyleSheet ??= MarkdownStyleSheet(
      p: GoogleFonts.quicksand(
        fontSize: 14.sp,
        color: AppTheme.textColor,
        height: 1.55,
      ),
      strong: GoogleFonts.quicksand(
        fontSize: 14.sp,
        color: AppTheme.textColor,
        fontWeight: FontWeight.w700,
        height: 1.55,
      ),
      em: GoogleFonts.quicksand(
        fontSize: 14.sp,
        color: AppTheme.textColor,
        fontStyle: FontStyle.italic,
        height: 1.55,
      ),
      h1: GoogleFonts.quicksand(
        fontSize: 18.sp,
        color: AppTheme.textColor,
        fontWeight: FontWeight.w700,
      ),
      h2: GoogleFonts.quicksand(
        fontSize: 16.sp,
        color: AppTheme.textColor,
        fontWeight: FontWeight.w700,
      ),
      h3: GoogleFonts.quicksand(
        fontSize: 15.sp,
        color: AppTheme.textColor,
        fontWeight: FontWeight.w600,
      ),
      listBullet: GoogleFonts.quicksand(
        fontSize: 14.sp,
        color: AppTheme.textColor,
        height: 1.55,
      ),
      code: GoogleFonts.sourceCodePro(
        fontSize: 13.sp,
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
      ),
      codeblockDecoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      blockquote: GoogleFonts.quicksand(
        fontSize: 14.sp,
        color: AppTheme.subTextColor,
        fontStyle: FontStyle.italic,
        height: 1.55,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
    );
  }

  const AiMessageBubble({
    super.key,
    required this.text,
    this.timestamp,
    this.isStreaming = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar trợ lý
          Container(
            width: 32.w,
            height: 32.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4D5DFA), Color(0xFF7B88FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 11.h,
                  ),
                  decoration: BoxDecoration(
                    color: isError
                        ? const Color(0xFFFFEBEE)
                        : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(18.r),
                      bottomRight: Radius.circular(18.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isError)
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFFD32F2F),
                            height: 1.55,
                          ),
                        )
                      else
                        MarkdownBody(
                          data: text,
                          softLineBreak: true,
                          extensionSet: md.ExtensionSet.gitHubFlavored,
                          onTapLink: (text, href, title) {
                            if (href == null) return;
                            final uri = Uri.tryParse(href);
                            if (uri == null) return;
                            CustomDialog.showConfirm(
                              context: context,
                              title: 'chatbot_open_link_title'.tr,
                              message: 'chatbot_open_link_message'.trParams({
                                'href': href,
                              }),
                              confirmText: 'chatbot_open_link_confirm'.tr,
                              cancelText: 'chatbot_cancel'.tr,
                              type: DialogType.info,
                              onConfirm: () async {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            );
                          },
                          styleSheet: _getStyleSheet(),
                        ),
                      // Cursor nhấp nháy khi đang stream
                      if (isStreaming)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: const BlinkingCursor(),
                        ),
                    ],
                  ),
                ),
                if (timestamp != null && !isStreaming)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w),
                    child: Text(
                      DateFormat('HH:mm').format(timestamp!),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }
}
