import 'package:flutter/material.dart';

import '../theme.dart';
import 'scan_screen.dart';
import 'chatbot_screen.dart';
import 'exam_home_screen.dart';
import 'puzzle_game_screen.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Hướng Dẫn Sử Dụng'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cẩm Nang SignEye',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Làm chủ mọi tính năng chỉ trong 5 phút',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'SignEye là ứng dụng thông minh hỗ trợ nhận diện biển báo giao thông bằng AI, tra cứu mức phạt theo Nghị định 168/2024, ôn thi sát hạch lý thuyết GPLX và giải đáp luật 24/7.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildGuideSection(
            stepNumber: '1',
            icon: Icons.camera_alt_rounded,
            iconColor: const Color(0xFF0D9488),
            title: 'Cách quét nhận diện biển báo bằng AI',
            subtitle: 'Chụp hoặc tải ảnh để AI phân tích tự động trong 1 giây',
            steps: [
              'Bấm vào nút "Quét biển báo ngay" ở trang chủ hoặc icon Camera ở thanh công cụ.',
              'Chọn chụp trực tiếp qua Camera hoặc chọn ảnh sẵn có trong thư viện máy của bạn.',
              'Căn chỉnh biển báo nằm trọn vẹn trong khung ngắm hình vuông, giữ chắc tay để ảnh rõ nét.',
              'Bấm nút "Chụp & Nhận diện". Hệ thống AI sẽ đọc và phân tích mã biển, tên biển, ý nghĩa và mức phạt theo quy định mới nhất.',
              'Mẹo: Chụp ở nơi có đủ ánh sáng, tránh góc quá nghiêng hoặc vật cản che khuất quá 50% biển.',
            ],
            actionLabel: 'Thử quét biển báo',
            onAction: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
          ),
          const SizedBox(height: 16),

          _buildGuideSection(
            stepNumber: '2',
            icon: Icons.search_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Tra cứu & So sánh 386 biển báo',
            subtitle: 'Đầy đủ dữ liệu chuẩn QCVN 41:2019/BGTVT',
            steps: [
              'Tại màn hình "Tra cứu", nhập từ khóa tên biển (ví dụ: "cấm quay đầu", "đường đôi", "P.102").',
              'Lọc theo 5 nhóm biển báo: Biển cấm (viền đỏ), Biển nguy hiểm (tam giác vàng), Biển hiệu lệnh (tròn xanh), Biển chỉ dẫn (chữ nhật xanh), Biển phụ (trắng).',
              'Xem chi tiết từng biển: Căn cứ pháp lý, mức phạt xe máy, mức phạt ô tô và quy định trừ điểm giấy phép lái xe.',
              'Tính năng So sánh: Chọn 2 - 3 biển báo có hình dáng tương tự nhau để đặt cạnh nhau so sánh chi tiết, tránh nhầm lẫn.',
            ],
          ),
          const SizedBox(height: 16),

          _buildGuideSection(
            stepNumber: '3',
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Trợ lý Chatbot AI tư vấn 24/7',
            subtitle: 'Giải đáp luật giao thông & hỗ trợ gửi hình ảnh',
            steps: [
              'Mở Chatbot AI từ nút tròn nổi (FAB) ở góc dưới hoặc banner ở Trang chủ.',
              'Nhập bất kỳ câu hỏi nào về luật giao thông đường bộ, mức phạt nguội, thủ tục sát hạch bằng lái.',
              'Tính năng gửi ảnh: Bấm icon 📷 trong khung chat để gửi ảnh biển báo hoặc tình huống giao thông, trợ lý AI sẽ phân tích và giải thích cụ thể cho bạn.',
            ],
            actionLabel: 'Chat với trợ lý AI',
            onAction: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AiChatbotScreen())),
          ),
          const SizedBox(height: 16),

          _buildGuideSection(
            stepNumber: '4',
            icon: Icons.fact_check_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Luyện thi sát hạch lý thuyết GPLX',
            subtitle: 'Đề thi trắc nghiệm trực quan với hình ảnh biển báo',
            steps: [
              'Vào mục "Thi GPLX" từ trang chủ để làm quen với các câu hỏi thực tế trong kỳ thi bằng lái.',
              'Chọn các gói đề thi hoặc làm đề ngẫu nhiên theo giấy phép lái xe A1, A2, B1, B2.',
              'Hệ thống chấm điểm tức thì, chỉ ra câu đúng/sai kèm giải thích chi tiết giúp bạn ghi nhớ nhanh.',
            ],
            actionLabel: 'Luyện thi ngay',
            onAction: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ExamHomeScreen())),
          ),
          const SizedBox(height: 16),

          _buildGuideSection(
            stepNumber: '5',
            icon: Icons.extension_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Chơi game kiếm xu đổi gói Pro miễn phí',
            subtitle: 'Tích lũy xu để mở khóa toàn bộ tính năng Pro',
            steps: [
              'Game "Ghép hình biển báo": Ghép đúng 25 mảnh ghép để nhận ngay +10 xu cho mỗi hình hoàn thành.',
              'Game "Đố vui biển báo": Trả lời đúng nhận ngay +5 xu cho mỗi câu hỏi.',
              'Đổi Pro bằng xu: Cứ 50 xu tương đương 5.000đ. Đủ 39.000đ bạn có thể đổi ngay gói Pro 1 tháng hoặc 75.000đ đổi Pro 2 tháng!',
            ],
            actionLabel: 'Chơi ghép hình kiếm xu',
            onAction: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PuzzleGameScreen())),
          ),
          const SizedBox(height: 16),

          _buildGuideSection(
            stepNumber: '6',
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFEA580C),
            title: 'Nâng cấp tài khoản SignEye Pro',
            subtitle: 'Quét không giới hạn và hỗ trợ ưu tiên',
            steps: [
              'Gói Pro mở khóa: Không giới hạn lượt quét mỗi ngày, phân tích AI ưu tiên tốc độ cao, hỗ trợ toàn diện.',
              'Thanh toán an toàn qua chuyển khoản VietQR tự động chỉ với 39.000đ/tháng.',
              'Sau khi quét mã thanh toán, tài khoản sẽ được hệ thống tự động kích hoạt ngay lập tức.',
            ],
          ),
          const SizedBox(height: 24),

          // FAQ Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded,
                        color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Câu hỏi thường gặp (FAQ)',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildFaqItem(
                  'Ứng dụng có thể tra cứu khi không có mạng (offline) không?',
                  'Có! Toàn bộ kho dữ liệu 386 biển báo, hình ảnh và câu hỏi ôn thi đều được tích hợp sẵn trên thiết bị, bạn có thể tra cứu mọi lúc mọi nơi kể cả khi mất mạng internet.',
                ),
                const Divider(height: 20),
                _buildFaqItem(
                  'Mức phạt và trừ điểm GPLX được cập nhật theo văn bản nào?',
                  'Dữ liệu mức xử phạt và quy định trừ điểm giấy phép lái xe được cập nhật chính xác theo Nghị định 168/2024/NĐ-CP và Luật Trật tự, an toàn giao thông đường bộ mới nhất.',
                ),
                const Divider(height: 20),
                _buildFaqItem(
                  'Làm sao để kiếm xu đổi Pro nhanh nhất?',
                  'Mỗi ngày bạn hãy vào mục "Ghép hình biển báo" (nhận 10 xu/hình) và trả lời "Đố vui biển báo" (5 xu/câu). Chỉ sau vài ngày chơi là bạn có thể đổi gói Pro hoàn toàn miễn phí!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required String stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> steps,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map((st) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 10),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        st,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: iconColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.text2,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
