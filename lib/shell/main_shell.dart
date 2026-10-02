import 'package:flutter/material.dart';
import '../core/theme/theme_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/feedback/feedback_screen.dart'; // <-- 1. Tambahkan import ini
import '../features/progres/progres_screen.dart';
import '../features/pt_ku/pt_ku_screen.dart';
import '../features/riwayat/riwayat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  // 2. Ganti PlaceholderTabScreen dengan FeedbackScreen()
  final List<Widget> _pages = const [
    DashboardScreen(),
    PtKuScreen(),
    ProgresScreen(),
    RiwayatScreen(),
    FeedbackScreen(), // <-- Ganti di sini
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bg,
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: context.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavItem(index: 0, icon: Icons.home_outlined, label: 'Beranda'),
              buildNavItem(index: 1, icon: Icons.sports, label: 'PT ku'),
              buildNavItem(index: 2, icon: Icons.trending_up_rounded, label: 'Progres'),
              buildNavItem(index: 3, icon: Icons.history_rounded, label: 'Riwayat'),
              buildNavItem(index: 4, icon: Icons.chat_bubble_rounded, label: 'Feedback'),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final Color activeColor = isSelected
        ? const Color(0xFFFF5520)
        : (context.isDark ? Colors.white : const Color(0xFF0E1714));
    final Color inactiveColor = context.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              currentIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}