import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:googleai_dart/googleai_dart.dart';

import '../../../config/demo_config.dart';

/// Đại diện cho một tin nhắn trong cuộc hội thoại.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class ChatbotController extends GetxController {
  // System prompt – định danh vai trò trợ lý giao thông

  static const String _systemPrompt = r'''
<role>
Bạn là TRAFFIC LAW ASSISTANT của Traffic App, chuyên tư vấn pháp luật giao thông đường bộ Việt Nam.
Phong cách: chính xác, súc tích, dễ đọc trên điện thoại, dùng Markdown. Không lặp lại câu hỏi. Không hiển thị quá trình suy luận nội bộ.
Ngôn ngữ: Người dùng hỏi bằng ngôn ngữ nào thì PHẢI trả lời hoàn toàn bằng chính ngôn ngữ đó (Language Mirroring).
</role>

<language_rule>
- BẮT BUỘC nhận diện ngôn ngữ trong câu hỏi MỚI NHẤT của người dùng và trả lời 100% bằng ngôn ngữ đó (ví dụ: hỏi tiếng Anh → trả lời tiếng Anh; hỏi tiếng Việt → trả lời tiếng Việt; hỏi tiếng Hàn/Nhật/Trung/Pháp... → trả lời đúng ngôn ngữ đó).
- Quá trình tra cứu Google Search vẫn dùng từ khóa tiếng Việt để tìm văn bản pháp luật Việt Nam, nhưng sau khi có kết quả, PHẢI dịch toàn bộ nội dung trả lời, giải thích và tiêu đề các mục sang ngôn ngữ câu hỏi của người dùng.
- Giữ nguyên số hiệu văn bản pháp luật Việt Nam (ví dụ: Nghị định 168/2024/NĐ-CP, Nghị định 238/2026/NĐ-CP, Luật TTATGT đường bộ 36/2024/QH15) hoặc ghi kèm tên dịch để người dùng dễ đối chiếu.
</language_rule>

<current_context>
Ngày hiện tại: {{NGAY_HIEN_TAI}} (dd/mm/yyyy). Đây là nguồn duy nhất để xác định văn bản nào đang có hiệu lực; không tự đoán ngày.
Nếu người dùng không nêu thời điểm vi phạm, mặc định là ngày hiện tại.
</current_context>

<legal_grounding_rules>
1. KHI NÀO PHẢI TRA CỨU: mọi câu hỏi về mức phạt, điểm/tước GPLX, tạm giữ/tịch thu, điều khoản, hiệu lực văn bản, biển báo, độ tuổi/điều kiện điều khiển phương tiện. Không tra cứu với chào hỏi, câu ngoài phạm vi, hoặc yêu cầu thuộc <app_boundaries>. Không dùng trí nhớ để chốt số liệu.

2. NGUYÊN TẮC "VĂN BẢN HIỆN HÀNH": Căn cứ pháp lý = văn bản gốc + TẤT CẢ văn bản sửa đổi, bổ sung, thay thế đã có hiệu lực tại thời điểm vi phạm. Danh sách ở mục 3 chỉ là mốc tối thiểu, không phải danh sách đầy đủ. Nếu tìm thấy văn bản mới hơn (ban hành sau NĐ 238/2026 hoặc sau ngày trong kết quả search), ưu tiên văn bản mới sau khi xác nhận tình trạng hiệu lực.

3. MỐC TỐI THIỂU:
   - Luật TTATGT đường bộ 36/2024/QH15; Luật Đường bộ 35/2024/QH15 (hiệu lực từ 01/01/2025).
   - Xử phạt & điểm GPLX: Nghị định 168/2024/NĐ-CP (hiệu lực từ 01/01/2025), được sửa đổi bởi Nghị định 238/2026/NĐ-CP (hiệu lực từ 15/08/2026).
   - Báo hiệu đường bộ: Thông tư 51/2024/TT-BGTVT (hiệu lực từ 01/01/2025).
   - Thẩm quyền xử phạt: NĐ 168/2024 (đã sửa bởi NĐ 238/2026) và Luật Xử lý vi phạm hành chính hiện hành.

4. ÁP DỤNG THEO THỜI ĐIỂM VI PHẠM:
   - Từ 15/08/2026 trở đi: NĐ 168/2024 đã được sửa bởi NĐ 238/2026.
   - Từ 01/01/2025 đến 14/08/2026: NĐ 168/2024 bản chưa sửa bởi NĐ 238. Chỉ khi tra cứu xác nhận NĐ 238 bỏ hành vi hoặc quy định chế tài nhẹ hơn thì mới nêu thêm khả năng áp dụng quy định có lợi theo Luật Xử lý vi phạm hành chính.
   - Trước 01/01/2025: NĐ 100/2019, NĐ 123/2021, QCVN 41:2019 chỉ khi người dùng nói rõ vi phạm xảy ra trong giai đoạn đó.
   - Hành vi diễn ra trước, xử lý sau: theo thời điểm vi phạm, không theo thời điểm hỏi.

5. THỨ TỰ NGUỒN:
   - Mức 1 (căn cứ chốt): vanban.chinhphu.vn, congbao.chinhphu.vn, vbpl.vn.
   - Mức 2 (bổ trợ): Cổng TTĐT Bộ Công an, Bộ Xây dựng / cơ quan quản lý giao thông.
   - Mức 2b (đối chiếu toàn văn): thuvienphapluat.vn, luatvietnam.vn, lsvn.vn. Chỉ dùng khi trang hiển thị nguyên văn điều/khoản; ghi rõ là bản đối chiếu.
   - Mức 3 (chỉ định hướng, không làm căn cứ chốt): báo chí.
   - Khi nguồn mâu thuẫn: Mức 1 > Mức 2 > Mức 2b > Mức 3.

6. QUY TRÌNH TRA CỨU NHANH:
   - Tối đa 2 lượt search, chạy song song: (a) xác định điều/khoản/điểm trong NĐ 168/2024 cho đúng hành vi và loại xe; (b) kiểm tra hành vi đó có bị NĐ 238/2026 hoặc văn bản mới hơn sửa không.
   - Mẫu truy vấn: "[hành vi bằng tiếng Việt] [loại phương tiện bằng tiếng Việt] Nghị định 168/2024 sửa đổi Nghị định 238/2026 điều khoản" (dịch hành vi sang tiếng Việt để search cho chính xác, nhưng kết quả trả lời cho User phải dịch sang ngôn ngữ của User).
   - Thêm lượt thứ 3 chỉ khi kết quả mâu thuẫn hoặc phát hiện văn bản mới hơn cần xác nhận hiệu lực.
   - Dừng ngay khi đã có đủ điều/khoản/mức phạt/điểm trừ từ nguồn Mức 1–2b. Không search thêm để "cho chắc".

7. CHỐNG BỊA ĐẶT:
   - Không tự chế số hiệu văn bản, điều/khoản/điểm, mức phạt, điểm trừ; không tự đoán URL.
   - Chỉ nêu con số xuất hiện trong nguồn đã đọc. Chỉ gắn URL có trong kết quả Search.
   - Nếu chỉ xác minh được một phần, trả lời phần đã xác minh và nói rõ phần nào chưa xác minh.
   - Nếu không đủ căn cứ, trả lời (bằng đúng ngôn ngữ của người dùng): "Tôi chưa xác minh được đầy đủ căn cứ pháp lý hiện hành để khẳng định mức xử phạt này. Tôi không muốn đưa ra một con số có thể sai luật. Bạn nên kiểm tra văn bản chính thức hoặc cung cấp thêm thông tin về tình huống." (hoặc bản dịch tương ứng sang ngôn ngữ người dùng đang hỏi).
</legal_grounding_rules>

<analysis_steps>
Phân tích ngầm trước khi trả lời, không in ra:
1. Thời điểm: hành vi xảy ra khi nào → chọn bản văn bản theo mục 4.
2. Chủ thể & phương tiện: ô tô / mô tô, xe gắn máy / xe máy điện / xe thô sơ / người đi bộ; người điều khiển vs chủ phương tiện; cá nhân vs tổ chức; độ tuổi người lái.
3. Tra cứu & đối chiếu: đúng điều, khoản, điểm; đã kiểm tra sửa đổi.
4. Chế tài: khung tiền phạt (min–max); phân biệt trừ điểm vs tước GPLX, tạm giữ vs tịch thu, biện pháp khắc phục hậu quả.
5. Thiếu dữ kiện: nếu dữ kiện làm đổi khung phạt (loại xe, nồng độ cồn, tốc độ vượt...), không tự áp khung cao nhất. Trả lời theo giả định hợp lý và nêu rõ giả định, hoặc hỏi lại đúng 1 câu ngắn.
6. Ngôn ngữ đầu ra: kiểm tra ngôn ngữ câu hỏi MỚI NHẤT của người dùng. Nếu không phải tiếng Việt, dịch toàn bộ đề mục và nội dung trả lời sang ngôn ngữ đó.
</analysis_steps>

<app_boundaries>
(Trả lời bằng đúng ngôn ngữ mà người dùng đã hỏi)
- Kẹt xe, sự cố, camera thời gian thực: không giả vờ kiểm tra được; hướng dẫn mở **Camera giao thông** (**Traffic Camera**) hoặc **Bản đồ** (**Map**) trên Traffic App.
- Phạt nguội theo biển số: không tự kết luận; hướng dẫn dùng **Tra cứu phạt nguội** (**Traffic Fine Lookup**) trên Traffic App hoặc cổng thông tin CSGT.
- Ngoài phạm vi giao thông: lịch sự từ chối và nêu rõ phạm vi hỗ trợ.
</app_boundaries>

<output_format>
- BẮT BUỘC trình bày toàn bộ câu trả lời và tiêu đề các mục bằng đúng ngôn ngữ của câu hỏi người dùng.
- Câu hỏi quy tắc/kiến thức đơn giản: trả lời trực tiếp, tối đa vài câu.
- Câu hỏi về vi phạm/mức phạt, dùng cấu trúc sau (bỏ mục không có quy định, tổng thể gọn cho màn hình điện thoại; dịch tiêu đề mục tương ứng với ngôn ngữ người dùng):
  + Khi hỏi bằng tiếng Việt:
    **Kết luận**: 1–2 câu.
    **Căn cứ pháp lý**: điểm, khoản, điều, số hiệu văn bản gốc + văn bản sửa đổi; ghi rõ bản áp dụng theo thời điểm vi phạm (ví dụ: "áp dụng từ 15/08/2026").
    **Mức xử phạt**: khung tiền phạt theo phương tiện/chủ thể; trừ điểm hoặc tước GPLX; tạm giữ/tịch thu (chỉ khi có quy định).
    **Lưu ý**: tình tiết đổi khung phạt, giả định đã dùng, hoặc 1 câu hỏi lại.
    **Nguồn chính thức**: chỉ URL lấy từ kết quả Search.
  + Khi hỏi bằng tiếng Anh (hoặc dịch tương đương sang ngôn ngữ khác của người dùng):
    **Conclusion**: 1–2 sentences.
    **Legal Basis**: point, clause, article, original decree/law code + amending decree code; specify effective version by violation date (e.g., "effective from 15/08/2026").
    **Penalties**: fine range by vehicle/subject; driving license point deduction or revocation; vehicle impoundment/confiscation (only if applicable).
    **Note**: aggravating factors, assumptions used, or 1 short clarifying question.
    **Official Sources**: only real URLs from Search results.
</output_format>

<few_shot_examples>
Quy ước: trong ví dụ, <...> là chỗ model phải điền bằng dữ liệu vừa tra cứu được. Tuyệt đối không giữ nguyên ký hiệu này và không điền số khi chưa tra cứu.

<example_1>
User: Vượt đèn đỏ bị phạt bao nhiêu?
Internal: Câu hỏi tiếng Việt -> trả lời tiếng Việt. Chưa rõ loại xe; thời điểm mặc định là hôm nay ({{NGAY_HIEN_TAI}}), áp dụng NĐ 168/2024 đã sửa bởi NĐ 238/2026 nếu từ 15/08/2026. Search 2 lượt song song. Trả lời theo 2 nhóm phổ biến (ô tô, mô tô/xe máy), giả định không gây tai nạn, hỏi lại 1 câu.
Assistant:
**Kết luận**
Không chấp hành hiệu lệnh đèn tín hiệu bị phạt tiền và trừ điểm GPLX tùy loại xe và hậu quả.

**Căn cứ pháp lý**
- NĐ 168/2024/NĐ-CP (sửa đổi bởi NĐ 238/2026/NĐ-CP, áp dụng từ 15/08/2026): ô tô <điểm/khoản/Điều đã tra>; mô tô, xe gắn máy <điểm/khoản/Điều đã tra>.

**Mức xử phạt** *(giả định không gây tai nạn)*
- **Ô tô**: <min–max đã tra> đồng; trừ <số điểm đã tra> điểm GPLX.
- **Mô tô, xe gắn máy**: <min–max đã tra> đồng; trừ <số điểm đã tra> điểm GPLX.

**Lưu ý**
- Gây tai nạn thì khung phạt và điểm trừ/tước GPLX nặng hơn.
- Bạn đang đi loại xe nào để mình chi tiết hóa?

**Nguồn chính thức**
- <tên văn bản + URL thật từ Search>
</example_1>

<example_2>
User: Kiểm tra giúp mình xe 30A-123.45 có bị phạt nguội ở ngã tư Khuất Duy Tiến không, và đoạn đó đang tắc đường không?
Assistant:
Tôi không thể truy cập dữ liệu vi phạm theo biển số hoặc camera thời gian thực qua trò chuyện. Bạn vui lòng dùng **Traffic App**:
- **Tra cứu phạt nguội**: nhập biển số `30A-123.45` để kiểm tra dữ liệu từ hệ thống CSGT.
- **Tình trạng giao thông**: mở **Bản đồ** hoặc **Camera giao thông** tại nút giao Khuất Duy Tiến.
</example_2>

<example_3>
User: Tháng 7 năm nay mình đi xe máy không đội mũ bảo hiểm, giờ bị phạt thì theo mức nào?
Internal: Câu hỏi tiếng Việt -> trả lời tiếng Việt. Vi phạm tháng 07/2026, tức trước 15/08/2026, nên áp dụng NĐ 168/2024 bản chưa sửa bởi NĐ 238. Search kiểm tra xem NĐ 238 có đổi hành vi/mức phạt này không; chỉ nhắc "quy định có lợi" nếu có thay đổi nhẹ hơn được xác nhận.
</example_3>

<example_4>
User: What is the fine for running a red light?
Internal: User asked in English -> MUST reply 100% in English. Vehicle type not specified; default date is today ({{NGAY_HIEN_TAI}}), apply Decree 168/2024/NĐ-CP as amended by Decree 238/2026/NĐ-CP. Search in Vietnamese ("vượt đèn đỏ Nghị định 168/2024 sửa đổi Nghị định 238/2026"), then translate all findings into English.
Assistant:
**Conclusion**
Failing to obey traffic light signals is subject to a monetary fine and driving license point deduction depending on the vehicle type and consequences.

**Legal Basis**
- Decree 168/2024/NĐ-CP (amended by Decree 238/2026/NĐ-CP, effective from 15/08/2026): cars <point/clause/Article looked up>; motorcycles/mopeds <point/clause/Article looked up>.

**Penalties** *(assuming no traffic accident caused)*
- **Cars**: <min–max looked up> VND; deduct <points looked up> driving license points.
- **Motorcycles / mopeds**: <min–max looked up> VND; deduct <points looked up> driving license points.

**Note**
- If the violation causes a traffic accident, the fine range and license point deduction/revocation will be more severe.
- Which type of vehicle are you driving so I can provide exact details?

**Official Sources**
- <document title + real URL from Search>
</example_4>
</few_shot_examples>

<critical_language_instruction>
CRITICAL FINAL INSTRUCTION:
Always detect the language of the user's latest message and write your entire response in that same language.
- If the user's message is in English, you MUST respond 100% in English (using **Conclusion**, **Legal Basis**, **Penalties**, **Note**, **Official Sources**), even though the Google Search results and legal documents are in Vietnamese.
- If the user's message is in Vietnamese, respond 100% in Vietnamese (using **Kết luận**, **Căn cứ pháp lý**, **Mức xử phạt**, **Lưu ý**, **Nguồn chính thức**).
- If the user's message is in any other language, respond 100% in that language.
</critical_language_instruction>
''';

  static const String _modelId = 'gemini-2.5-flash-lite';

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final streamingText = ''.obs;

  final textController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();

  late GoogleAIClient _client;
  bool _hasApiKey = false;
  StreamSubscription<GenerateContentResponse>? _streamSubscription;
  DateTime? _lastScrollTime;

  final suggestions = const [
    'chatbot_suggestion_1',
    'chatbot_suggestion_2',
    'chatbot_suggestion_3',
    'chatbot_suggestion_4',
    'chatbot_suggestion_5',
    'chatbot_suggestion_6',
    'chatbot_suggestion_7',
    'chatbot_suggestion_8',
    'chatbot_suggestion_9',
    'chatbot_suggestion_10',
  ];

  @override
  void onInit() {
    super.onInit();
    _initClient();
    _addWelcomeMessage();
  }

  void _initClient() {
    final rawKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final apiKey = rawKey.trim();
    _hasApiKey =
        !DemoConfig.isDemoMode &&
        apiKey.isNotEmpty &&
        apiKey != 'YOUR_GEMINI_API_KEY_HERE' &&
        apiKey != 'DEMO_MODE';
    debugPrint('[Chatbot] hasApiKey=$_hasApiKey, keyLength=${apiKey.length}');
    if (_hasApiKey) {
      _client = GoogleAIClient(
        config: GoogleAIConfig(authProvider: ApiKeyProvider(apiKey)),
      );
    }
  }

  void _addWelcomeMessage() {
    messages.clear();
    messages.add(
      ChatMessage(
        id: 'welcome',
        text: 'chatbot_welcome'.tr,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isTyping.value) return;

    if (DemoConfig.isDemoMode || !_hasApiKey) {
      if (DemoConfig.isDemoMode) {
        await _handleSimulatedResponse(trimmed);
        return;
      }
      Get.snackbar(
        'chatbot_config_error'.tr,
        'chatbot_config_error_message'.tr,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Thêm tin nhắn người dùng
    messages.add(
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_user',
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    textController.clear();
    _scrollToBottom(force: true);

    isTyping.value = true;
    streamingText.value = '';

    // Xây dựng lịch sử hội thoại (loại bỏ welcome và error messages)
    final validMessages = messages
        .where((m) => m.id != 'welcome' && !m.isError)
        .toList();
    final conversationContents = <Content>[];
    for (var i = 0; i < validMessages.length; i++) {
      final m = validMessages[i];
      if (m.isUser) {
        final isLast = i == validMessages.length - 1;
        final promptText = isLast
            ? '${m.text}\n\n[System Reminder: You MUST reply 100% in the exact same language used in the user question above. If the question is in English, translate all findings and section headers into English. If in Vietnamese, reply in Vietnamese.]'
            : m.text;
        conversationContents.add(Content.user([Part.text(promptText)]));
      } else {
        conversationContents.add(Content.model([Part.text(m.text)]));
      }
    }

    final completer = Completer<void>();
    String fullText = '';

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final resolvedSystemPrompt = _systemPrompt.replaceAll(
      '{{NGAY_HIEN_TAI}}',
      formattedDate,
    );

    try {
      final stream = _client.models.streamGenerateContent(
        model: _modelId,
        request: GenerateContentRequest(
          systemInstruction: Content(
            parts: [
              Part.text(
                'Ngày hiện tại: $formattedDate (${now.toIso8601String()})\n\n'
                '$resolvedSystemPrompt',
              ),
            ],
          ),
          contents: conversationContents,
          tools: [Tool(googleSearch: {})],
          generationConfig: const GenerationConfig(
            temperature: 0.1,
            maxOutputTokens: 800,
          ),
        ),
      );

      _streamSubscription = stream.listen(
        (chunk) {
          final chunkText = chunk.text;
          if (chunkText != null && chunkText.isNotEmpty) {
            fullText += chunkText;
            streamingText.value = fullText;
            _scrollToBottom();
          }
        },
        onError: (Object error, StackTrace st) {
          if (!completer.isCompleted) {
            completer.completeError(error, st);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: true,
      );

      await completer.future;

      if (fullText.isNotEmpty) {
        messages.add(
          ChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_ai',
            text: fullText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[Chatbot] API error: $e');
      debugPrint('[Chatbot] Stack: $st');
      final errStr = e.toString();
      final String errorMsg;
      if (errStr.contains('429')) {
        errorMsg = 'chatbot_error_quota'.tr;
      } else if (errStr.contains('401') || errStr.contains('403')) {
        errorMsg = 'chatbot_error_auth'.tr;
      } else if (errStr.contains('404')) {
        errorMsg = 'chatbot_error_not_found'.tr;
      } else if (errStr.contains('SocketException') ||
          errStr.contains('network') ||
          errStr.contains('connection')) {
        errorMsg = 'chatbot_error_network'.tr;
      } else {
        errorMsg =
            '${'chatbot_error_generic'.tr}\n(${errStr.substring(0, errStr.length.clamp(0, 100))})';
      }
      messages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          text: errorMsg,
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _streamSubscription = null;
      streamingText.value = '';
      isTyping.value = false;
      _scrollToBottom(force: true);
    }
  }

  /// Trả lời mô phỏng thông minh cho Web Demo không cần API Key bên ngoài
  Future<void> _handleSimulatedResponse(String text) async {
    messages.add(
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_user',
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    textController.clear();
    _scrollToBottom(force: true);

    isTyping.value = true;
    streamingText.value = '';

    final String reply = _buildSimulatedReply(text);

    // Mô phỏng hiệu ứng typing gõ chữ mượt mà theo cụm từ
    final words = reply.split(' ');
    String current = '';
    const int chunkSize = 3;
    for (int i = 0; i < words.length; i += chunkSize) {
      if (!isTyping.value) return;
      await Future.delayed(const Duration(milliseconds: 18));
      if (!isTyping.value) return;
      final end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
      final chunk = words.sublist(i, end).join(' ');
      current += (current.isEmpty ? '' : ' ') + chunk;
      streamingText.value = current;
      _scrollToBottom();
    }

    messages.add(
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    isTyping.value = false;
    streamingText.value = '';
    _scrollToBottom(force: true);
  }

  String _buildSimulatedReply(String text) {
    final lower = text.toLowerCase();
    final bool isEnglish =
        lower.contains('how ') ||
        lower.contains('what ') ||
        lower.contains('penalt') ||
        lower.contains('fine') ||
        lower.contains('traffic sign') ||
        lower.contains('red light') ||
        lower.contains('alcohol') ||
        lower.contains('speeding') ||
        lower.contains('helmet') ||
        lower.contains('wrong lane') ||
        lower.contains('accident') ||
        lower.contains('12-point') ||
        lower.contains('stuck in traffic');

    // 1. Kiểm tra phạt nguội / Đăng ký thông báo biển số
    if (lower.contains('phạt nguội') ||
        lower.contains('tra cứu') ||
        lower.contains('biển số') ||
        lower.contains('check traffic fines') ||
        lower.contains('license plate')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'You can look up traffic fines and subscribe to automatic license plate violation alerts directly in **Traffic App**.\n\n'
            '**How to check on Traffic App**\n'
            '1. Open the **Discovery (Tra cứu)** tab on the bottom navigation bar.\n'
            '2. Select your vehicle type (**Car**, **Motorcycle**, or **Electric bike**).\n'
            '3. Enter your license plate (e.g., `30A-123.45` or `29B1-678.90`) and tap **Search**.\n'
            '4. Tap the **Bell icon (🔔)** at the top right to register your license plate for automatic violation push notifications.\n\n'
            '**Note**\n'
            '- Try demo plates `30A12345` (has unpaid & paid records) or `51G99999` (clean record) in the **Discovery** tab!';
      }
      return '**Kết luận**\n'
          'Bạn có thể kiểm tra phạt nguội và đăng ký nhận thông báo vi phạm tự động theo biển số ngay trên **Traffic App**.\n\n'
          '**Hướng dẫn thực hiện trên ứng dụng**\n'
          '1. Mở tab **Tra cứu** ở thanh điều hướng phía dưới màn hình.\n'
          '2. Chọn loại phương tiện (**Ô tô**, **Xe máy** hoặc **Xe máy điện**).\n'
          '3. Nhập biển số xe (ví dụ: `30A-123.45` hoặc `29B1-678.90`) và nhấn **Tra cứu**.\n'
          '4. Nhấn vào **biểu tượng Chuông (🔔)** góc trên bên phải để đăng ký nhận thông báo tự động khi biển số phát sinh lỗi phạt nguội mới.\n\n'
          '**Mẹo trải nghiệm Bản Demo**\n'
          '- Bạn có thể thử nhập biển số mẫu `30A12345` (có dữ liệu vi phạm mẫu) hoặc biển số bất kỳ tại tab **Tra cứu** để xem chi tiết biên bản!';
    }

    // 2. Mức phạt vượt đèn đỏ / đèn vàng
    if (lower.contains('đèn đỏ') ||
        lower.contains('đèn vàng') ||
        lower.contains('tín hiệu đèn') ||
        lower.contains('red light')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Failing to obey traffic light signals (running a red or yellow light) results in heavy monetary fines and driving license point deductions.\n\n'
            '**Legal Basis**\n'
            '- Point b Clause 9 Article 6 & Point c Clause 7 Article 7 of **Decree 168/2024/NĐ-CP** (effective from 01/01/2025).\n\n'
            '**Penalties** *(assuming no accident caused)*\n'
            '- **Cars**: Fine from **18,000,000 – 20,000,000 VND**; deduct **04 points** from the driving license *(if causing an accident: **20,000,000 – 22,000,000 VND**, deduct **10 points**)*.\n'
            '- **Motorcycles / Mopeds**: Fine from **4,000,000 – 6,000,000 VND**; deduct **04 points** from the driving license *(if causing an accident: **10,000,000 – 14,000,000 VND**, deduct **10 points**)*.\n'
            '- **Bicycles / Non-motorized vehicles**: Fine from **150,000 – 250,000 VND**.\n\n'
            '**Note**\n'
            '- Running a yellow light when youhave not yet crossed the stop line is penalized the same as running a red light.';
      }
      return '**Kết luận**\n'
          'Hành vi không chấp hành hiệu lệnh của đèn tín hiệu giao thông (vượt đèn đỏ, đèn vàng) bị xử phạt tiền ở mức rất nghiêm khắc kèm trừ điểm Giấy phép lái xe (GPLX).\n\n'
          '**Căn cứ pháp lý**\n'
          '- Điểm b Khoản 9 Điều 6 và Điểm c Khoản 7 Điều 7 **Nghị định 168/2024/NĐ-CP** (áp dụng theo Luật TTATGT đường bộ 36/2024/QH15).\n\n'
          '**Mức xử phạt** *(giả định không gây tai nạn)*\n'
          '- **Đối với Ô tô**: Phạt tiền từ **18.000.000đ – 20.000.000đ**, trừ **04 điểm** GPLX *(nếu gây tai nạn giao thông: phạt **20.000.000đ – 22.000.000đ**, trừ **10 điểm** GPLX)*.\n'
          '- **Đối với Xe máy (mô tô, xe gắn máy)**: Phạt tiền từ **4.000.000đ – 6.000.000đ**, trừ **04 điểm** GPLX *(nếu gây tai nạn giao thông: phạt **10.000.000đ – 14.000.000đ**, trừ **10 điểm** GPLX)*.\n'
          '- **Đối với Xe đạp, xe thô sơ**: Phạt tiền từ **150.000đ – 250.000đ**.\n\n'
          '**Lưu ý**\n'
          '- Khi đèn chuyển vàng, người lái xe phải dừng lại trước vạch dừng; trường hợp đã đi quá vạch dừng hoặc quá gần vạch dừng nếu dừng lại thấy nguy hiểm thì được đi tiếp.';
    }

    // 3. Mức phạt nồng độ cồn
    if (lower.contains('nồng độ cồn') ||
        lower.contains('rượu') ||
        lower.contains('bia') ||
        lower.contains('thổi cồn') ||
        lower.contains('alcohol') ||
        lower.contains('drunk')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Vietnam applies a **zero-tolerance policy** for alcohol concentration while driving. Any detected alcohol level results in fines, point deductions, or license revocation.\n\n'
            '**Legal Basis**\n'
            '- Article 6 (Cars) and Article 7 (Motorcycles) of **Decree 168/2024/NĐ-CP**.\n\n'
            '**Penalties by Alcohol Level**\n'
            '1. **Level 1** *(≤ 50 mg/100ml blood or ≤ 0.25 mg/L breath)*:\n'
            '   - **Motorcycles**: **2,000,000 – 3,000,000 VND**, deduct **04 points**.\n'
            '   - **Cars**: **6,000,000 – 8,000,000 VND**, deduct **04 points**.\n'
            '2. **Level 2** *(> 50 to 80 mg/100ml blood or > 0.25 to 0.4 mg/L breath)*:\n'
            '   - **Motorcycles**: **6,000,000 – 8,000,000 VND**, deduct **10 points**.\n'
            '   - **Cars**: **18,000,000 – 20,000,000 VND**, deduct **10 points**.\n'
            '3. **Level 3** *(> 80 mg/100ml blood or > 0.4 mg/L breath, or refusing test)*:\n'
            '   - **Motorcycles**: **8,000,000 – 10,000,000 VND**, **revoke license for 22 – 24 months**.\n'
            '   - **Cars**: **30,000,000 – 40,000,000 VND**, **revoke license for 22 – 24 months**.\n\n'
            '**Note**\n'
            '- Law enforcement may also temporarily impound the vehicle for up to **07 working days**.';
      }
      return '**Kết luận**\n'
          'Pháp luật Việt Nam nghiêm cấm tuyệt đối điều khiển phương tiện khi trong máu hoặc hơi thở có nồng độ cồn (**đã uống rượu bia – không lái xe**).\n\n'
          '**Căn cứ pháp lý**\n'
          '- Điều 6 (Ô tô) và Điều 7 (Mô tô, xe gắn máy) **Nghị định 168/2024/NĐ-CP**.\n\n'
          '**Mức xử phạt chi tiết theo 3 khung**\n'
          '1. **Mức 1** *(Chưa vượt quá 50 mg/100ml máu hoặc 0,25 mg/lít khí thở)*:\n'
          '   - **Xe máy**: Phạt **2.000.000đ – 3.000.000đ**, trừ **04 điểm** GPLX.\n'
          '   - **Ô tô**: Phạt **6.000.000đ – 8.000.000đ**, trừ **04 điểm** GPLX.\n'
          '2. **Mức 2** *(Vượt quá 50 đến 80 mg/100ml máu hoặc 0,25 đến 0,4 mg/lít khí thở)*:\n'
          '   - **Xe máy**: Phạt **6.000.000đ – 8.000.000đ**, trừ **10 điểm** GPLX.\n'
          '   - **Ô tô**: Phạt **18.000.000đ – 20.000.000đ**, trừ **10 điểm** GPLX.\n'
          '3. **Mức 3** *(Vượt quá 80 mg/100ml máu hoặc 0,4 mg/lít khí thở, hoặc không chấp hành kiểm tra)*:\n'
          '   - **Xe máy**: Phạt **8.000.000đ – 10.000.000đ**, **tước GPLX 22 – 24 tháng**.\n'
          '   - **Ô tô**: Phạt **30.000.000đ – 40.000.000đ**, **tước GPLX 22 – 24 tháng**.\n\n'
          '**Lưu ý**\n'
          '- Tất cả các mức vi phạm nồng độ cồn đều bị **tạm giữ phương tiện đến 07 ngày làm việc**.';
    }

    // 4. Lỗi chạy quá tốc độ
    if (lower.contains('tốc độ') ||
        lower.contains('quá tốc độ') ||
        lower.contains('bắn tốc độ') ||
        lower.contains('speed')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Speeding penalties depend on how many km/h you exceed the posted limit and the vehicle type.\n\n'
            '**Legal Basis**\n'
            '- Article 6 & Article 7 of **Decree 168/2024/NĐ-CP**.\n\n'
            '**Penalties**\n'
            '- **Exceeding by 05 to < 10 km/h**:\n'
            '  + Motorcycles: **400,000 – 600,000 VND** | Cars: **800,000 – 1,000,000 VND**.\n'
            '- **Exceeding by 10 to 20 km/h**:\n'
            '  + Motorcycles: **800,000 – 1,000,000 VND** | Cars: **4,000,000 – 6,000,000 VND** (deduct **02 points**).\n'
            '- **Exceeding by > 20 to 35 km/h**:\n'
            '  + Motorcycles: **4,000,000 – 6,000,000 VND** (deduct **04 points**) | Cars: **6,000,000 – 8,000,000 VND** (deduct **04 points**).\n'
            '- **Exceeding by > 35 km/h**:\n'
            '  + Motorcycles: **6,000,000 – 8,000,000 VND** (deduct **04 points**) | Cars: **12,000,000 – 14,000,000 VND** (deduct **06 points**).';
      }
      return '**Kết luận**\n'
          'Mức phạt chạy quá tốc độ quy định được chia thành 4 nấc tùy theo mức tốc độ vượt (từ 05 km/h đến trên 35 km/h).\n\n'
          '**Căn cứ pháp lý**\n'
          '- Điều 6 (Ô tô) và Điều 7 (Mô tô, xe gắn máy) **Nghị định 168/2024/NĐ-CP**; Thông tư 38/2024/TT-BGTVT về tốc độ và khoảng cách an toàn.\n\n'
          '**Mức xử phạt chi tiết**\n'
          '- **Vượt từ 05 km/h đến dưới 10 km/h**:\n'
          '  + **Xe máy**: Phạt **400.000đ – 600.000đ**.\n'
          '  + **Ô tô**: Phạt **800.000đ – 1.000.000đ**.\n'
          '- **Vượt từ 10 km/h đến 20 km/h**:\n'
          '  + **Xe máy**: Phạt **800.000đ – 1.000.000đ**.\n'
          '  + **Ô tô**: Phạt **4.000.000đ – 6.000.000đ**, trừ **02 điểm** GPLX.\n'
          '- **Vượt trên 20 km/h đến 35 km/h**:\n'
          '  + **Xe máy**: Phạt **4.000.000đ – 6.000.000đ**, trừ **04 điểm** GPLX.\n'
          '  + **Ô tô**: Phạt **6.000.000đ – 8.000.000đ**, trừ **04 điểm** GPLX.\n'
          '- **Vượt trên 35 km/h**:\n'
          '  + **Xe máy**: Phạt **6.000.000đ – 8.000.000đ**, trừ **04 điểm** GPLX.\n'
          '  + **Ô tô**: Phạt **12.000.000đ – 14.000.000đ**, trừ **06 điểm** GPLX.\n\n'
          '**Lưu ý**\n'
          '- Trong khu vực đông dân cư (biển `R.420`), tốc độ tối đa cho phép thường là **60 km/h** (đường đôi/1 chiều ≥ 2 làn) hoặc **50 km/h** (đường 2 chiều).';
    }

    // 5. Đi sai làn đường / Đè vạch kẻ đường
    if (lower.contains('sai làn') ||
        lower.contains('làn đường') ||
        lower.contains('đè vạch') ||
        lower.contains('vạch kẻ') ||
        lower.contains('wrong lane') ||
        lower.contains('crossing line')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Vietnamese traffic law clearly distinguishes between **"failing to obey road markings/lane arrows"** and **"driving in the wrong lane"**.\n\n'
            '**Legal Basis**\n'
            '- Article 6 & Article 7 of **Decree 168/2024/NĐ-CP**.\n\n'
            '**Penalties**\n'
            '1. **Crossing solid lines / disobeying lane direction arrows (`R.411`)**:\n'
            '   - **Motorcycles**: **200,000 – 400,000 VND**.\n'
            '   - **Cars**: **400,000 – 600,000 VND**.\n'
            '2. **Driving in the wrong lane (lane designated for another vehicle type or opposite direction)**:\n'
            '   - **Motorcycles**: **600,000 – 800,000 VND** *(if causing an accident: **10,000,000 – 14,000,000 VND**, deduct **10 points**)*.\n'
            '   - **Cars**: **4,000,000 – 6,000,000 VND**, deduct **02 points** *(if causing an accident: **20,000,000 – 22,000,000 VND**, deduct **10 points**)*.\n'
            '3. **Driving motorcycles on the sidewalk** *(except to enter a house/office)*:\n'
            '   - **Motorcycles**: **4,000,000 – 6,000,000 VND**, deduct **02 points**.';
      }
      return '**Kết luận**\n'
          'Bạn cần phân biệt rõ 2 lỗi rất dễ nhầm lẫn: **Không chấp hành vạch kẻ đường (đè vạch, đi sai mũi tên)** và **Đi sai làn đường quy định**.\n\n'
          '**Căn cứ pháp lý**\n'
          '- Điều 6 và Điều 7 **Nghị định 168/2024/NĐ-CP**.\n\n'
          '**Mức xử phạt chi tiết**\n'
          '1. **Lỗi không chấp hành hiệu lệnh vạch kẻ đường** *(đè vạch liền, đi thẳng ở làn chỉ cho rẽ trái theo biển `R.411`)*:\n'
          '   - **Xe máy**: Phạt **200.000đ – 400.000đ**.\n'
          '   - **Ô tô**: Phạt **400.000đ – 600.000đ**.\n'
          '2. **Lỗi đi không đúng làn đường, phần đường quy định (Đi sai làn)** *(ví dụ: xe máy đi vào làn dành riêng cho ô tô có biển phân làn `R.412`)*:\n'
          '   - **Xe máy**: Phạt **600.000đ – 800.000đ** *(nếu gây tai nạn: phạt **10.000.000đ – 14.000.000đ**, trừ **10 điểm** GPLX)*.\n'
          '   - **Ô tô**: Phạt **4.000.000đ – 6.000.000đ**, trừ **02 điểm** GPLX *(nếu gây tai nạn: phạt **20.000.000đ – 22.000.000đ**, trừ **10 điểm** GPLX)*.\n'
          '3. **Lỗi điều khiển xe máy đi trên vỉa hè** *(trừ trường hợp đi qua vỉa hè để vào nhà/cơ quan)*:\n'
          '   - **Xe máy**: Phạt **4.000.000đ – 6.000.000đ**, trừ **02 điểm** GPLX.';
    }

    // 6. Không đội mũ bảo hiểm
    if (lower.contains('mũ bảo hiểm') ||
        lower.contains('mbh') ||
        lower.contains('cài quai') ||
        lower.contains('helmet')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Both riders and passengers on motorcycles, mopeds, and electric bikes must wear a standard helmet with the strap properly fastened.\n\n'
            '**Legal Basis**\n'
            '- Point h, i Clause 2 Article 7 of **Decree 168/2024/NĐ-CP**.\n\n'
            '**Penalties**\n'
            '- **Rider or passenger not wearing a helmet (or unfastened strap)**: Fine from **400,000 – 600,000 VND** per violating person.\n'
            '- **If both rider and passenger do not wear helmets**: Total fine from **800,000 – 1,200,000 VND**.\n\n'
            '**Note**\n'
            '- Exemptions apply when transporting a patient for emergency medical care, children under **06 years old**, or escorting lawbreakers.';
      }
      return '**Kết luận**\n'
          'Người điều khiển và người ngồi trên xe mô tô, xe gắn máy, xe máy điện bắt buộc phải đội mũ bảo hiểm và cài quai đúng quy cách.\n\n'
          '**Căn cứ pháp lý**\n'
          '- Điểm h, Điểm i Khoản 2 Điều 7 **Nghị định 168/2024/NĐ-CP**.\n\n'
          '**Mức xử phạt**\n'
          '- **Người điều khiển không đội MBH** (hoặc đội nhưng không cài quai đúng quy cách): Phạt **400.000đ – 600.000đ**.\n'
          '- **Chở người ngồi trên xe không đội MBH**: Phạt **400.000đ – 600.000đ**.\n'
          '- **Trường hợp cả người lái và người ngồi sau đều vi phạm**: Tổng mức phạt cho cả 2 hành vi là **800.000đ – 1.200.000đ**.\n\n'
          '**Lưu ý**\n'
          '- Không xử phạt khi chở người bệnh đi cấp cứu, trẻ em **dưới 06 tuổi**, hoặc áp giải người có hành vi vi phạm pháp luật.';
    }

    // 7. Quy định trừ 12 điểm giấy phép lái xe & Điểm uy tín
    if (lower.contains('12 điểm') ||
        lower.contains('trừ điểm') ||
        lower.contains('giấy phép lái xe') ||
        lower.contains('gplx') ||
        lower.contains('bằng lái') ||
        lower.contains('uy tín') ||
        lower.contains('12-point') ||
        lower.contains('point deduction') ||
        lower.contains('driving license')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Each Vietnamese Driving License is allocated **12 points per year** under the Law on Road Traffic Order and Safety 2024.\n\n'
            '**Legal Basis**\n'
            '- Article 58 of **Law 36/2024/QH15** and **Decree 168/2024/NĐ-CP**.\n\n'
            '**Key Rules**\n'
            '- **Point Scale**: Each license starts with **12 points**. Violations deduct **2, 4, 6, or 10 points** depending on severity.\n'
            '- **Automatic Restoration**: If at least 01 point remains and no further points are deducted within **12 months** from the last deduction, all **12 points** are automatically restored.\n'
            '- **When all 12 points are deducted**: You are prohibited from driving vehicles under that license. After at least **06 months**, you must pass a traffic law knowledge test organized by the Traffic Police to restore 12 points.';
      }
      return '**Kết luận**\n'
          'Theo Luật Trật tự, an toàn giao thông đường bộ 2024, mỗi Giấy phép lái xe (GPLX) có quỹ **12 điểm/năm**.\n\n'
          '**Căn cứ pháp lý**\n'
          '- Điều 58 **Luật TTATGT đường bộ 36/2024/QH15** và **Nghị định 168/2024/NĐ-CP**.\n\n'
          '**Cơ chế trừ điểm & phục hồi điểm GPLX**\n'
          '1. **Mức điểm trừ**: Tùy tính chất lỗi vi phạm, người lái xe bị trừ **02, 04, 06 hoặc 10 điểm** ngay khi quyết định xử phạt có hiệu lực.\n'
          '2. **Tự động phục hồi 12 điểm**: Nếu GPLX chưa bị trừ hết điểm và không bị trừ thêm điểm nào trong thời hạn **12 tháng** kể từ ngày bị trừ điểm gần nhất thì được **phục hồi đủ 12 điểm**.\n'
          '3. **Khi bị trừ hết 12 điểm**:\n'
          '   - Người có GPLX không được điều khiển phương tiện tham gia giao thông theo GPLX đó.\n'
          '   - Sau ít nhất **06 tháng** kể từ ngày bị trừ hết điểm, người lái xe phải tham gia **kiểm tra nội dung kiến thức pháp luật về TTATGT đường bộ** do Cục CSGT tổ chức; nếu đạt yêu cầu sẽ được phục hồi đủ **12 điểm**.\n\n'
          '**Lưu ý trên Traffic App**\n'
          '- Ngoài điểm GPLX, bạn còn có **Điểm uy tín cộng đồng** trong mục **Hồ sơ / Bảng xếp hạng** khi đóng góp bài đăng giao thông chính xác!';
    }

    // 8. Biển báo giao thông cần biết
    if (lower.contains('biển báo') ||
        lower.contains('biển cấm') ||
        lower.contains('hiệu lệnh') ||
        lower.contains('traffic sign')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'Road traffic signs in Vietnam are standardized into **5 main groups** under National Technical Regulation **QCVN 41 / Circular 51/2024/TT-BGTVT**.\n\n'
            '**5 Essential Sign Groups**\n'
            '1. **Prohibitory Signs (Biển báo cấm)**: Circular, **red border, white background** (e.g., `P.102` No Entry, `P.123a` No Left Turn, `P.130` No Stopping & Parking).\n'
            '2. **Warning Signs (Biển báo nguy hiểm)**: Equilateral triangle, **red border, yellow background, black symbol** (e.g., sharp curves, pedestrian crossing, road work).\n'
            '3. **Mandatory Signs (Biển hiệu lệnh)**: Circular, **blue background, white symbol** (e.g., `R.301` Mandatory direction, `R.412` Dedicated vehicle lanes).\n'
            '4. **Guide Signs (Biển chỉ dẫn)**: Rectangular/square, **blue background** (e.g., `R.420` Start of densely populated area – speed limit 50–60 km/h, `R.411` Lane direction arrows).\n'
            '5. **Supplementary Signs (Biển phụ)**: Rectangular white/black plates placed below main signs to specify vehicle types or time windows.';
      }
      return '**Kết luận**\n'
          'Hệ thống biển báo hiệu đường bộ Việt Nam (theo **QCVN 41** & **Thông tư 51/2024/TT-BGTVT**) gồm **5 nhóm chính** người lái xe cần nắm vững:\n\n'
          '**1. Biển báo cấm (Mã P)**\n'
          '- **Đặc điểm**: Hình tròn, viền đỏ, nền trắng, hình vẽ màu đen.\n'
          '- **Biển quan trọng**: `P.102` (Cấm đi ngược chiều), `P.123a/b` (Cấm rẽ trái/phải), `P.124` (Cấm quay đầu), `P.130` (Cấm dừng và đỗ xe – 2 gạch chéo), `P.131` (Cấm đỗ xe – 1 gạch chéo).\n\n'
          '**2. Biển báo nguy hiểm và cảnh báo (Mã W)**\n'
          '- **Đặc điểm**: Hình tam giác đều, viền đỏ, nền vàng, hình vẽ đen.\n'
          '- **Ý nghĩa**: Cảnh báo trước các tình huống nguy hiểm (giao nhau với đường ưu tiên, đường hẹp, trẻ em, công trường) để chủ động giảm tốc.\n\n'
          '**3. Biển hiệu lệnh (Mã R)**\n'
          '- **Đặc điểm**: Hình tròn, nền xanh lam, hình vẽ trắng.\n'
          '- **Biển quan trọng**: `R.301` (Hướng đi phải theo), `R.412` (Làn đường dành riêng cho từng loại xe – đi sai bị tính lỗi **sai làn**).\n\n'
          '**4. Biển chỉ dẫn (Mã I / R.4xx)**\n'
          '- **Đặc điểm**: Hình chữ nhật hoặc hình vuông, nền xanh lam.\n'
          '- **Biển quan trọng**: `R.420` (Bắt đầu khu đông dân cư – giới hạn tốc độ 50–60 km/h), `R.421` (Hết khu đông dân cư), `R.411` (Hướng đi trên mỗi làn đường theo vạch kẻ).\n\n'
          '**5. Biển phụ (Mã S)**\n'
          '- Đặt dưới biển chính để bổ sung phạm vi hiệu lực, khung giờ cấm hoặc loại phương tiện áp dụng.';
    }

    // 9. Tắc đường / Tình hình giao thông
    if (lower.contains('tắc') ||
        lower.contains('ùn') ||
        lower.contains('kẹt') ||
        lower.contains('ngập') ||
        lower.contains('stuck in traffic') ||
        lower.contains('traffic jam')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'When encountering traffic congestion, stay in your proper lane and use **Traffic App\'s Real-time Map** to find alternative routes.\n\n'
            '**Current Area Traffic Highlights (Web Demo)**\n'
            '- **Kim Mã – Liễu Giai Intersection**: Heavy traffic volume (`#ketxe`), moving slowly at ~15 km/h.\n'
            '- **Nguyễn Trãi – Khuất Duy Tiến Underpass**: Minor collision reported (`#tainan`), authorities are regulating traffic.\n'
            '- **Thái Hà – Chùa Bộc**: Localized waterlogging (`#ngaplutnuoc`), motorcycles should avoid the inner lane.\n\n'
            '**What you should do**\n'
            '1. Open the **Map (Bản đồ)** tab and filter by `#ketxe` or radius `1km – 5km` to inspect nearby congestion clusters.\n'
            '2. **Never drive on the sidewalk** (fine of **4,000,000 – 6,000,000 VND** for motorcycles under Decree 168/2024/NĐ-CP) or enter the emergency lane on expressways.\n'
            '3. Share a photo report via the **Camera** tab to alert other drivers and earn **+5 reputation points**!';
      }
      return '**Kết luận**\n'
          'Khi gặp ùn tắc giao thông, bạn nên giữ đúng làn đường, tuân thủ điều tiết của CSGT và kiểm tra lộ trình thay thế trên tab **Bản đồ**.\n\n'
          '**Tình hình giao thông nổi bật (Dữ liệu Bản đồ Demo)**\n'
          '- **Nút giao Kim Mã – Liễu Giai**: Lưu lượng phương tiện rất đông (`#ketxe`), di chuyển chậm ~15 km/h.\n'
          '- **Hầm chui Nguyễn Trãi – Khuất Duy Tiến**: Có va chạm nhẹ (`#tainan`), lực lượng chức năng đang phân luồng.\n'
          '- **Phố Thái Hà – Chùa Bộc**: Có điểm ngập cục bộ (`#ngaplutnuoc`), xe máy nên hạn chế đi sát lề phải.\n\n'
          '**Kinh nghiệm & Lưu ý pháp lý khi tắc đường**\n'
          '1. **Mở tab Bản đồ**: Bấm vào bộ lọc `#ketxe`, `#ngaplutnuoc` hoặc lọc bán kính `1km – 5km` để chọn hướng rẽ tránh điểm nghẽn.\n'
          '2. **Tuyệt đối không leo vỉa hè**: Theo NĐ 168/2024/NĐ-CP, xe máy đi trên vỉa hè bị phạt **4.000.000đ – 6.000.000đ** và trừ **02 điểm** GPLX.\n'
          '3. **Không đi vào làn khẩn cấp trên cao tốc**: Ô tô vi phạm bị phạt **4.000.000đ – 6.000.000đ** và trừ **02 điểm** GPLX.\n'
          '4. **Đóng góp cảnh báo**: Bạn có thể chụp ảnh tại tab **Camera** kèm hashtag `#ketxe` để nhận ngay **+5 điểm uy tín**!';
    }

    // 10. Tai nạn / Cứu hộ SOS khẩn cấp
    if (lower.contains('tai nạn') ||
        lower.contains('va chạm') ||
        lower.contains('cứu hộ') ||
        lower.contains('sos') ||
        lower.contains('khẩn cấp') ||
        lower.contains('accident') ||
        lower.contains('emergency')) {
      if (isEnglish) {
        return '**Conclusion**\n'
            'If a traffic accident or breakdown occurs, prioritize human safety, place hazard warnings immediately, and broadcast an **SOS signal** on **Traffic App**.\n\n'
            '**5-Step Emergency Protocol**\n'
            '1. **Turn on Hazard Lights & Place Warnings**: Activate hazard flashers and place reflective warning triangles at least **50m** behind your vehicle (**100m** on expressways).\n'
            '2. **Call Emergency Services**: Dial **115** (Medical Emergency) if anyone is injured, and **113** (Traffic Police).\n'
            '3. **Broadcast SOS on Traffic App**: Tap the red **SOS** button on the Home or Map screen and select **"Broadcast SOS"** to share your live GPS coordinates with nearby drivers and your trusted contact.\n'
            '4. **Document the Scene**: Take photos of vehicle positions, license plates, and skid marks before moving vehicles.\n'
            '5. **Legal Duty**: Never flee the scene or refuse to assist injured victims (fleeing an accident carries a fine of **16,000,000 – 18,000,000 VND** and **06 points** deduction, or criminal liability).';
      }
      return '**Kết luận**\n'
          'Khi xảy ra tai nạn hoặc sự cố khẩn cấp trên đường, ưu tiên hàng đầu là đảm bảo an toàn tính mạng, đặt cảnh báo từ xa và phát tín hiệu **SOS Cứu hộ**.\n\n'
          '**Quy trình 5 bước xử lý chuẩn an toàn & pháp luật**\n'
          '1. **Bật đèn khẩn cấp & Đặt cảnh báo**: Bật đèn Hazard và đặt biển tam giác phản quang cách đuôi xe tối thiểu **50m** (trên cao tốc tối thiểu **100m**).\n'
          '2. **Gọi cấp cứu & lực lượng chức năng**: Gọi ngay **115** (Cấp cứu y tế) nếu có người bị thương và **113** (Cảnh sát giao thông).\n'
          '3. **Phát tín hiệu SOS trên Traffic App**: Nhấn nút **Trợ giúp khẩn cấp (SOS)** và chọn **"Phát tín hiệu cứu hộ"** để ghim tọa độ Radar đỏ lên Bản đồ thời gian thực và gọi nhanh cho người thân.\n'
          '4. **Giữ hiện trường & Chụp ảnh**: Chụp lại vị trí xe, biển số, vạch kẻ đường làm căn cứ giải quyết hoặc giám định bảo hiểm.\n'
          '5. **Lưu ý pháp lý (NĐ 168/2024/NĐ-CP)**: Hành vi gây tai nạn rồi bỏ chạy hoặc không cứu giúp người bị nạn bị phạt tới **16.000.000đ – 18.000.000đ**, trừ **06 điểm** GPLX (hoặc truy cứu trách nhiệm hình sự).';
    }

    // Câu trả lời mặc định khi người dùng hỏi chung chung
    if (isEnglish) {
      return 'Hello! I am the **AI Traffic Assistant** of **Traffic App** (Web Demo).\n\n'
          'I can help you look up **Decree 168/2024/NĐ-CP** traffic penalties and guide you through the app:\n'
          '- 🚦 **Fine Lookup**: Check license plate fines & subscribe to alerts\n'
          '- 📋 **Red Light Penalties**: 4–6M VND (motorcycles), 18–20M VND (cars)\n'
          '- 🍺 **Alcohol Limits**: 3 penalty tiers & license point deductions\n'
          '- ⚡ **Speeding & Wrong Lane**: Detailed fine brackets & road markings\n'
          '- 🪪 **12-Point License System**: Deduction & restoration rules\n'
          '- 🚗 **Emergency SOS & Traffic Signs**: Step-by-step safety guides\n\n'
          '👉 Tap any of the **Quick Ask** chips below or type your question to get started!';
    }

    return 'Xin chào! Tôi là **Trợ lý Giao thông AI** của **Traffic App** (Phiên bản Web Demo).\n\n'
        'Tôi có thể tư vấn chi tiết quy định pháp luật giao thông mới nhất (**Luật TTATGT đường bộ 2024 & Nghị định 168/2024/NĐ-CP**):\n'
        '- 🚦 **Tra cứu phạt nguội & Đăng ký theo dõi biển số xe**\n'
        '- 📋 **Mức phạt vượt đèn đỏ**: Xe máy **4 – 6 triệu**, Ô tô **18 – 20 triệu**\n'
        '- 🍺 **Nồng độ cồn**: Chi tiết 3 khung phạt tiền & trừ điểm/tước GPLX\n'
        '- ⚡ **Chạy quá tốc độ, đi sai làn, đè vạch kẻ đường, không đội MBH**\n'
        '- 🪪 **Quy định 12 điểm Giấy phép lái xe** & cách phục hồi điểm\n'
        '- 🚗 **Kinh nghiệm xử lý tai nạn, tắc đường & phát tín hiệu SOS**\n\n'
        '👉 Bạn hãy nhấn trực tiếp vào các **câu hỏi gợi ý bên dưới** hoặc nhập câu hỏi bất kỳ để mình giải đáp ngay nhé!';
  }

  void clearChat() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    streamingText.value = '';
    isTyping.value = false;
    messages.clear();
    textController.clear();
    _addWelcomeMessage();
  }

  void _scrollToBottom({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastScrollTime != null &&
        now.difference(_lastScrollTime!).inMilliseconds < 120) {
      return;
    }
    _lastScrollTime = now;

    Future.delayed(const Duration(milliseconds: 80), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    if (_hasApiKey) _client.close();
    super.onClose();
  }
}
