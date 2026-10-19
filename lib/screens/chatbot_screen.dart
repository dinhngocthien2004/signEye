import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/chatbot_service.dart';
import '../services/data_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/sign_detail_sheet.dart';

class AiChatbotScreen extends StatefulWidget {
  final String? initialPrompt;
  final String? initialSampleAsset;
  final List<TrafficSign>? catalog;

  const AiChatbotScreen({
    super.key,
    this.initialPrompt,
    this.initialSampleAsset,
    this.catalog,
  });

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  List<TrafficSign> _allSigns = [];

  bool _loading = false;
  Uint8List? _stagedImageBytes;
  String? _stagedSampleAsset;
  String? _stagedImageLabel;

  @override
  void initState() {
    super.initState();
    if (widget.catalog != null && widget.catalog!.isNotEmpty) {
      _allSigns = widget.catalog!;
    } else {
      _loadCatalog();
    }

    // Add initial greeting from AI assistant
    _messages.add(
      ChatMessage(
        id: 'welcome',
        isUser: false,
        text: '👋 **Xin chào! Tôi là Trợ lý AI SignEye.**\n\n'
            'Tôi sẵn sàng hỗ trợ bạn:\n'
            '• 📷 **Gửi hình ảnh** để nhận diện mã biển báo, ý nghĩa và mức phạt ngay lập tức.\n'
            '• 🔍 **Tra cứu chi tiết** theo mã biển (như `P.102`, `W.205`, `R.301`) hoặc tên biển.\n'
            '• 🚦 **Hỏi đáp luật giao thông** và mức phạt vi phạm mới nhất theo Nghị định 100 & 123.\n'
            '• 💡 **Giải đáp tình huống thi GPLX** (như "Cấm rẽ trái có được quay đầu không?").\n\n'
            'Hãy nhập câu hỏi hoặc bấm nút 📷 / 🖼️ bên dưới để gửi ảnh biển báo nhé!',
        suggestedFollowUps: [
          '📷 Gửi ảnh nhận diện biển báo',
          'Biển cấm đi ngược chiều P.102',
          'Biển cấm rẽ trái có được quay đầu?',
          'Mức phạt vượt đèn đỏ mới nhất',
        ],
        timestamp: DateTime.now(),
      ),
    );

    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialPrompt!);
      });
    } else if (widget.initialSampleAsset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendSampleImage(widget.initialSampleAsset!, 'Ảnh biển mẫu');
      });
    }
  }

  Future<void> _loadCatalog() async {
    final signs = await DataService.instance.loadSigns();
    if (mounted) {
      setState(() => _allSigns = signs);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _stagedImageBytes = bytes;
        _stagedSampleAsset = null;
        _stagedImageLabel = 'Ảnh chụp / thư viện';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  void _selectSampleImage(SampleSignImage sample) {
    setState(() {
      _stagedImageBytes = null;
      _stagedSampleAsset = sample.assetPath;
      _stagedImageLabel = '${sample.code} - ${sample.name}';
    });
  }

  void _handleSendSampleImage(String assetPath, String label) {
    setState(() {
      _stagedImageBytes = null;
      _stagedSampleAsset = assetPath;
      _stagedImageLabel = label;
    });
    _handleSendMessage('Nhận diện biển báo trong ảnh này giúp tôi');
  }

  void _openSampleImagesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn ảnh mẫu biển báo để tra cứu',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Bấm vào một biển báo mẫu để gửi ngay vào Chatbot AI phân tích:',
                style: TextStyle(fontSize: 12, color: AppColors.text2),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: ChatbotAiService.sampleImages.length,
                itemBuilder: (context, i) {
                  final sample = ChatbotAiService.sampleImages[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectSampleImage(sample);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Image.asset(sample.assetPath, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sample.code,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primary),
                          ),
                          Text(
                            sample.name,
                            style: const TextStyle(fontSize: 9.5, color: AppColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Chụp ảnh từ Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Chụp ảnh trực diện biển báo phía trước'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('Chọn ảnh từ Thư viện', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Tải ảnh biển báo sẵn có từ thiết bị'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.grid_view_rounded, color: Color(0xFF059669)),
                ),
                title: const Text('Chọn ảnh mẫu biển báo (Thử nghiệm nhanh)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Chọn từ kho ảnh biển báo chuẩn của SignEye'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSampleImagesSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendMessage([String? overrideText]) async {
    final text = (overrideText ?? _textCtrl.text).trim();
    final hasImage = _stagedImageBytes != null || _stagedSampleAsset != null;

    if (text.isEmpty && !hasImage) return;

    final state = context.read<AppState>();
    final userText = text.isNotEmpty ? text : 'Nhận diện biển báo trong ảnh này';

    // 1. Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: userText,
      imageBytes: _stagedImageBytes,
      imageAssetPath: _stagedSampleAsset,
      timestamp: DateTime.now(),
    );

    final sentBytes = _stagedImageBytes;
    final sentAsset = _stagedSampleAsset;

    setState(() {
      _messages.add(userMsg);
      _textCtrl.clear();
      _stagedImageBytes = null;
      _stagedSampleAsset = null;
      _stagedImageLabel = null;
      _loading = true;
    });

    _scrollToBottom();

    // 2. Query Chatbot AI Service
    if (_allSigns.isEmpty) {
      _allSigns = await DataService.instance.loadSigns();
    }

    final botReply = await ChatbotAiService.instance.reply(
      prompt: userText,
      imageBytes: sentBytes,
      imageAssetPath: sentAsset,
      catalog: _allSigns,
      apiKey: state.geminiApiKey,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(botReply);
      _loading = false;
    });

    _scrollToBottom();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đoạn chat?'),
        content: const Text('Bạn có chắc muốn xóa lịch sử trò chuyện hiện tại không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    id: 'welcome_again',
                    isUser: false,
                    text: '👋 Đoạn chat đã được làm mới. Bạn có thể gửi ảnh hoặc đặt câu hỏi mới về biển báo giao thông!',
                    suggestedFollowUps: [
                      '📷 Gửi ảnh nhận diện biển báo',
                      'Biển cấm đi ngược chiều P.102',
                      'Mức phạt vượt đèn đỏ',
                    ],
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Trợ lý AI SignEye',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Tra cứu & gửi ảnh nhận diện 24/7',
                    style: TextStyle(fontSize: 11, color: AppColors.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chọn ảnh mẫu thử nghiệm',
            icon: const Icon(Icons.grid_view_rounded, size: 22),
            onPressed: _openSampleImagesSheet,
          ),
          IconButton(
            tooltip: 'Làm mới đoạn chat',
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _loading) {
                  return _buildLoadingBubble();
                }
                final msg = _messages[i];
                return _buildMessageItem(msg);
              },
            ),
          ),

          // Staged image bar if user attached an image
          if (_stagedImageBytes != null || _stagedSampleAsset != null)
            _buildStagedImagePreview(),

          // Bottom Input Controls
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              _stagedImageBytes != null || _stagedSampleAsset != null
                  ? 'AI đang phân tích ảnh biển báo...'
                  : 'AI đang soạn câu trả lời...',
              style: const TextStyle(fontSize: 12.5, color: AppColors.text2, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(msg.imageBytes!, width: 140, height: 140, fit: BoxFit.cover),
                ),
                const SizedBox(height: 6),
              ] else if (msg.imageAssetPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(msg.imageAssetPath!, width: 90, height: 90, fit: BoxFit.contain),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3),
              ),
            ],
          ),
        ),
      );
    }

    // Bot message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primaryPale,
                  child: const Text('🤖', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          msg.text,
                          style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.text),
                        ),

                        // Interactive Traffic Sign Card if detected
                        if (msg.identifiedSign != null) ...[
                          const SizedBox(height: 10),
                          _buildIdentifiedSignCard(msg.identifiedSign!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Quick Follow-up Chips
            if (msg.suggestedFollowUps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: msg.suggestedFollowUps.map((chipText) {
                    return InkWell(
                      onTap: () {
                        if (chipText.contains('Gửi ảnh')) {
                          _openImageSourceSheet();
                        } else {
                          _handleSendMessage(chipText);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              chipText,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifiedSignCard(TrafficSign sign) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Image.asset(sign.image, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sign.maBien,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sign.tenBien,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sign.nhomBien.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: AppColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => showSignDetailSheet(context, sign, allSigns: _allSigns, source: 'chatbot'),
                  icon: const Icon(Icons.info_outline_rounded, size: 14),
                  label: const Text('Xem chi tiết biển', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                tooltip: 'Nghe đọc to',
                icon: const Icon(Icons.volume_up_rounded, size: 16),
                onPressed: () => TtsService.instance.speak(sign.speechText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStagedImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _stagedImageBytes != null
                ? Image.memory(_stagedImageBytes!, width: 44, height: 44, fit: BoxFit.cover)
                : Image.asset(_stagedSampleAsset!, width: 44, height: 44, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh đính kèm đã sẵn sàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(_stagedImageLabel ?? 'Ảnh biển báo', style: const TextStyle(fontSize: 11, color: AppColors.text2)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              setState(() {
                _stagedImageBytes = null;
                _stagedSampleAsset = null;
                _stagedImageLabel = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach image button
            IconButton(
              tooltip: 'Gửi ảnh biển báo',
              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              onPressed: _openImageSourceSheet,
            ),
            IconButton(
              tooltip: 'Chọn ảnh mẫu biển',
              icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF6366F1)),
              onPressed: _openSampleImagesSheet,
            ),
            // Text input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  key: const Key('chatbot_input_field'),
                  controller: _textCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Hỏi AI hoặc gửi ảnh biển báo...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send button
            IconButton(
              key: const Key('chatbot_send_btn'),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
              onPressed: () => _handleSendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}
