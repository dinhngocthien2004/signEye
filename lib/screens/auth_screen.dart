import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginTab = true;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final name = isLoginTab ? _emailCtrl.text.split('@').first : _nameCtrl.text;
    state.login(name: name, email: _emailCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFDEF7F3), AppColors.bg],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.remove_red_eye_rounded,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SignEye',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Tra cứu biển báo giao thông bằng ảnh, giọng nói\nvà học lý thuyết GPLX ngay trên điện thoại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.text2, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _tabButton('Đăng nhập', true)),
                      Expanded(child: _tabButton('Đăng ký', false)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isLoginTab) ...[
                        _fieldLabel('Họ và tên'),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration:
                              const InputDecoration(hintText: 'Nguyễn Văn A'),
                          validator: (v) =>
                              (!isLoginTab && (v == null || v.trim().isEmpty))
                                  ? 'Vui lòng nhập họ tên'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _fieldLabel('Email'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(hintText: 'ban@email.com'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email không hợp lệ'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Mật khẩu'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: '••••••••'),
                        validator: (v) => (v == null || v.length < 4)
                            ? 'Mật khẩu tối thiểu 4 ký tự'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child:
                              Text(isLoginTab ? 'Đăng nhập' : 'Tạo tài khoản'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Dữ liệu tài khoản được lưu trên thiết bị (bản demo)',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text2)),
      );

  Widget _tabButton(String label, bool loginTab) {
    final active = isLoginTab == loginTab;
    return GestureDetector(
      onTap: () => setState(() => isLoginTab = loginTab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: active ? AppColors.primary : AppColors.text2,
          ),
        ),
      ),
    );
  }
}
