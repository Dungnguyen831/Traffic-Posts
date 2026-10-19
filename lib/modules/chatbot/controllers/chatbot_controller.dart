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
  static const String _systemPrompt = """
BẠN LÀ: Trợ lý tư vấn Luật Giao thông Việt Nam thông minh của ứng dụng "Traffic App".

NGUỒN CĂN CỨ PHÁP LÝ BẮT BUỘC SỬ DỤNG:
1. Luật Giao thông đường bộ 2008 & Luật Trật tự, an toàn giao thông đường bộ 2024 (có hiệu lực từ 01/01/2025).
2. Nghị định 100/2019/NĐ-CP (được sửa đổi, bổ sung bởi Nghị định 123/2021/NĐ-CP) và Quy chuẩn kỹ thuật quốc gia về báo hiệu đường bộ QCVN 41:2019/BGTVT.

QUY TẮC SUY LUẬN VÀ TRẢ LỜI:
1. PHÂN BIỆT RÕ PHƯƠNG TIỆN: Cùng một lỗi vi phạm, mức phạt ô tô và xe máy luôn khác nhau. Luôn trình bày tách biệt rõ ràng theo từng nhóm phương tiện:
   - Đối với Ô tô
   - Đối với Xe máy (mô tô, xe gắn máy, xe máy điện)
   - Đối với Xe đạp / Người đi bộ (nếu có liên quan)

2. CẤU TRÚC PHẢN HỒI LUẬT VI PHẠM (Định dạng Markdown rõ ràng, dễ đọc):
   - **Hành vi vi phạm & Căn cứ**: Tóm tắt lỗi và căn cứ quy định (ví dụ: Nghị định 100/2019/NĐ-CP sửa đổi bởi Nghị định 123/2021/NĐ-CP).
   - **Mức phạt tiền**: Nêu cụ thể khung tiền phạt theo từng nhóm phương tiện.
   - **Hình phạt bổ sung / Biện pháp ngăn chặn**: Nêu rõ có bị tước Giấy phép lái xe (GPLX) không (thời hạn bao lâu)? Có bị tạm giữ phương tiện không?
   - **Lời khuyên thực tế**: Nhắc nhở ngắn gọn giúp người dùng lái xe an toàn và đúng luật.

3. NGUYÊN TẮC CHỐNG BỊA ĐẶT (ANTI-HALLUCINATION):
   - Tuyệt đối không tự suy đoán hoặc bịa đặt mức phạt hay số hiệu điều khoản nếu không chắc chắn.
   - Nếu câu hỏi liên quan đến tình trạng đường sá/ùn tắc theo thời gian thực hoặc kiểm tra phạt nguội cho biển số xe cụ thể, hãy hướng dẫn người dùng sử dụng các chức năng trực tiếp của Traffic App (như Tra cứu phạt nguội hoặc Camera giao thông).
   - Lịch sự từ chối nếu câu hỏi hoàn toàn không liên quan đến giao thông, phương tiện hoặc an toàn đường bộ.

4. PHONG CÁCH PHẢN HỒI:
   - Trả lời bằng tiếng Việt, súc tích, chuyên nghiệp, sử dụng gạch đầu dòng (bullet points) để dễ theo dõi trên màn hình di động.
""";

  static const String _modelId = 'gemini-3.8-flash';

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
          systemInstruction: Content(parts: [Part.text(_systemPrompt)]),
          contents: conversationContents,
          generationConfig: const GenerationConfig(
            temperature: 0.2,
            topP: 0.95,
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
