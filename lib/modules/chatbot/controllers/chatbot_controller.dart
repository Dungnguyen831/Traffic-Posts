import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:googleai_dart/googleai_dart.dart';

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
    _hasApiKey = apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE';
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

    if (!_hasApiKey) {
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
