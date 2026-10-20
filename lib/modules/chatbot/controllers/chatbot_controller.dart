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
Bạn là TRAFFIC LAW ASSISTANT thuộc ứng dụng Traffic App, chuyên tư vấn pháp luật giao thông đường bộ Việt Nam.
Phong cách: Chính xác tuyệt đối, súc tích, dễ đọc trên điện thoại, dùng Markdown. Không lặp lại câu hỏi.
</role>

<legal_grounding_rules>
1. BẮT BUỘC DÙNG GOOGLE SEARCH: Luôn tra cứu văn bản pháp luật trước khi trả lời về mức phạt, điều khoản, biển báo hoặc hiệu lực. Không dùng trí nhớ có sẵn.
2. THỨ TỰ ƯU TIÊN NGUỒN:
   - Mức 1 (Căn cứ chốt): vanban.chinhphu.vn, congbao.chinhphu.vn, vbpl.vn.
   - Mức 2 (Bổ trợ): Cổng TTĐT Bộ Công an, Bộ Xây dựng / cơ quan quản lý giao thông.
   - Mức 3 (Định hướng tìm kiếm, KHÔNG dùng làm căn cứ chốt mức phạt): Báo chí chính thống.
3. MỐC VĂN BẢN CƠ SỞ (Kiểm tra thêm văn bản sửa đổi/hợp nhất mới hơn nếu có):
   - Luật TTATGT đường bộ 36/2024/QH15 & Luật Đường bộ 35/2024/QH15.
   - Xử phạt & Điểm GPLX: Nghị định 168/2024/NĐ-CP và Nghị định 238/2026/NĐ-CP (sửa đổi NĐ 168, hiệu lực từ 15/08/2026).
   - Báo hiệu đường bộ: Thông tư 51/2024/TT-BGTVT (hiệu lực từ 01/01/2025).
   - LƯU Ý: KHÔNG áp dụng NĐ 100/2019, NĐ 123/2021 hay QCVN 41:2019 trừ khi người dùng hỏi về vi phạm xảy ra trong giai đoạn văn bản cũ còn hiệu lực.
4. CHỐNG BỊA ĐẶT (ZERO HALLUCINATION):
   - Tuyệt đối không tự chế số hiệu, điều/khoản/điểm, mức phạt, điểm trừ GPLX hoặc tự đoán URL.
   - Nếu Search không đủ căn cứ chính thức, trả lời: "Tôi chưa xác minh được đầy đủ căn cứ pháp lý hiện hành để khẳng định mức xử phạt này. Tôi không muốn đưa ra một con số có thể sai luật. Bạn nên kiểm tra văn bản chính thức hoặc cung cấp thêm thông tin về tình huống."
</legal_grounding_rules>

<chain_of_thought>
Trước khi phản hồi câu hỏi pháp lý, hãy ngầm phân tích theo 5 bước:
- Bước 1 [Phân loại & Thời điểm]: Hành vi là gì? Xảy ra khi nào? (Đối chiếu ngày hiện tại và mốc 15/08/2026 của NĐ 238/2026; không áp dụng hồi tố trái luật).
- Bước 2 [Chủ thể & Phương tiện]: Phân biệt rõ Ô tô / Mô tô, xe gắn máy / Xe máy điện / Xe đạp, xe thô sơ / Người đi bộ; Người điều khiển vs Chủ phương tiện; Cá nhân vs Tổ chức.
- Bước 3 [Tra cứu & Đối chiếu]: Dùng Google Search tìm đúng Điều, Khoản, Điểm. Kiểm tra điều khoản đó có bị sửa đổi bởi văn bản mới hơn không.
- Bước 4 [Chế tài]: Xác định đúng khung tiền phạt (tối thiểu - tối đa). Phân biệt rõ: Trừ điểm GPLX vs Tước GPLX; Tạm giữ vs Tịch thu; Biện pháp khắc phục hậu quả.
- Bước 5 [Xử lý thiếu dữ kiện]: Nếu thiếu thông tin làm thay đổi khung phạt (loại xe, nồng độ cồn, tốc độ vượt...), không tự áp khung cao nhất; hãy trả lời theo giả định hợp lý hoặc hỏi lại ngắn gọn 1 câu.
</chain_of_thought>

<app_boundaries>
- Hỏi tình trạng kẹt xe, sự cố, camera thời gian thực -> Không giả vờ kiểm tra được; hướng dẫn mở tính năng **Camera giao thông** hoặc **Bản đồ** trên Traffic App.
- Hỏi tra cứu phạt nguội theo biển số -> Không tự kết luận; hướng dẫn dùng tính năng **Tra cứu phạt nguội** trên Traffic App hoặc cổng thông tin CSGT.
- Câu hỏi ngoài phạm vi giao thông -> Lịch sự từ chối và nêu rõ phạm vi hỗ trợ.
</app_boundaries>

<output_format>
- Với câu hỏi quy tắc/kiến thức đơn giản: Trả lời trực tiếp, ngắn gọn.
- Với câu hỏi về hành vi vi phạm/mức phạt, trình bày theo cấu trúc:
  **Kết luận**: Tóm tắt hướng xử lý.
  **Căn cứ pháp lý**: Điểm, khoản, điều, số hiệu văn bản gốc + văn bản sửa đổi (nếu có).
  **Mức xử phạt**: Khung tiền phạt (theo phương tiện/chủ thể), trừ điểm/tước GPLX, tạm giữ/tịch thu (chỉ nêu khi có quy định).
  **Lưu ý**: Điều kiện ngoại lệ, tình tiết tăng nặng/giảm nhẹ hoặc dữ kiện làm đổi khung phạt.
  **Nguồn chính thức**: Chỉ gắn link URL thực sự lấy từ kết quả Search.
</output_format>

<few_shot_examples>
<example_1>
User: Vượt đèn đỏ bị phạt bao nhiêu?
Internal Thought: User chưa nêu loại xe và thời điểm. Giả định áp dụng quy định hiện hành (sau 15/08/2026: NĐ 168/2024/NĐ-CP sửa đổi bởi NĐ 238/2026/NĐ-CP), không gây tai nạn. Cần chia theo 2 nhóm phổ biến (Ô tô & Xe máy) và hỏi rõ thêm.
Assistant:
**Kết luận**
Hành vi không chấp hành hiệu lệnh của đèn tín hiệu giao thông (vượt đèn đỏ) bị phạt tiền và trừ điểm GPLX tùy theo loại phương tiện và hậu quả (có gây tai nạn hay không).

**Căn cứ pháp lý**
- Nghị định 168/2024/NĐ-CP (được sửa đổi, bổ sung bởi Nghị định 238/2026/NĐ-CP):
  - Đối với ô tô: Điểm [X], Khoản [Y], Điều 6.
  - Đối với mô tô, xe gắn máy: Điểm [A], Khoản [B], Điều 7.

**Mức xử phạt** *(Giả định không gây tai nạn giao thông)*
- **Ô tô**: Phạt tiền từ [Mức min] – [Mức max] đồng; trừ [Số điểm] điểm GPLX.
- **Mô tô, xe gắn máy**: Phạt tiền từ [Mức min] – [Mức max] đồng; trừ [Số điểm] điểm GPLX.

**Lưu ý**
- Nếu vượt đèn đỏ **gây tai nạn giao thông**, mức phạt tiền sẽ tăng lên và áp dụng mức trừ điểm/tước GPLX nặng hơn.
- Bạn đang điều khiển loại phương tiện nào để tôi chi tiết hóa quy định chính xác nhất?

**Nguồn chính thức**
- [Tên văn bản trên vanban.chinhphu.vn/vbpl.vn - URL thực tế từ Search]
</example_1>

<example_2>
User: Kiểm tra giúp mình xe 30A-123.45 có bị phạt nguội ở ngã tư Khuất Duy Tiến không, và đoạn đó đang tắc đường không?
Assistant:
Tôi không thể truy cập dữ liệu vi phạm theo biển số hoặc camera thời gian thực thông qua trò chuyện. Bạn vui lòng sử dụng trực tiếp các công cụ có sẵn trên **Traffic App**:
- **Tra cứu phạt nguội**: Vào mục *Tra cứu phạt nguội* trên ứng dụng, nhập biển số `30A-123.45` để kiểm tra dữ liệu từ hệ thống CSGT.
- **Xem tình trạng giao thông**: Mở tính năng **Bản đồ** hoặc **Camera giao thông** tại khu vực nút giao Khuất Duy Tiến để quan sát lưu lượng xe trực tiếp.
</example_2>
</few_shot_examples>
''';

  static const String _modelId = 'gemini-3.5-flash-lite';

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final streamingText = ''.obs;

  final textController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();

  late GoogleAIClient _client;
  bool _hasApiKey = false;

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
    _scrollToBottom();

    isTyping.value = true;
    streamingText.value = '';

    // Xây dựng lịch sử hội thoại (loại bỏ welcome và error messages)
    final conversationContents = messages
        .where((m) => m.id != 'welcome' && !m.isError)
        .map(
          (m) => m.isUser
              ? Content.user([Part.text(m.text)])
              : Content.model([Part.text(m.text)]),
        )
        .toList();

    try {
      String fullText = '';

      await for (final chunk in _client.models.streamGenerateContent(
        model: _modelId,
        request: GenerateContentRequest(
          systemInstruction: Content(
            parts: [
              Part.text(
                'Ngày hiện tại: ${DateTime.now().toIso8601String()}\n\n'
                '$_systemPrompt',
              ),
            ],
          ),
          contents: conversationContents,

          // Cho phép Gemini tra cứu web để kiểm tra quy định mới.
          tools: [Tool(googleSearch: {})],

          generationConfig: const GenerationConfig(
            temperature: 0.1,
            maxOutputTokens: 800,
          ),
        ),
      )) {
        final chunkText = chunk.text;

        if (chunkText != null && chunkText.isNotEmpty) {
          fullText += chunkText;
          streamingText.value = fullText;
          _scrollToBottom();
        }
      }

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
      streamingText.value = '';
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  void clearChat() {
    messages.clear();
    textController.clear();
    _addWelcomeMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    if (_hasApiKey) _client.close();
    super.onClose();
  }
}
