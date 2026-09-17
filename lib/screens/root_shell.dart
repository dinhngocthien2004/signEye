import 'package:flutter/material.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'account_screen.dart';

/// Hosts the 5 main screens behind the bottom nav bar, exactly like the
/// `#bottomNav` in the original `index.html` (Trang chủ / Tra cứu / [Scan] /
/// Lịch sử / Tài khoản).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    HistoryScreen(),
    AccountScreen(),
  ];

  void _openScan() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // _index maps: 0 home, 1 search, 2 history, 3 account (scan opens a page)
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              _navItem(icon: Icons.home_rounded, label: 'Trang chủ', idx: 0),
              _navItem(icon: Icons.search_rounded, label: 'Tra cứu', idx: 1),
              _scanButton(),
              _navItem(icon: Icons.history_rounded, label: 'Lịch sử', idx: 2),
              _navItem(icon: Icons.person_rounded, label: 'Tài khoản', idx: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int idx}) {
    final active = _index == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primaryPale : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: active ? AppColors.primary : AppColors.muted),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openScan,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 7)),
            ],
          ),
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
