import 'package:flutter/material.dart';
import '../core/theme/theme_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/pt_ku/pt_ku_screen.dart';
import '../features/progres/progres_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    PtKuScreen(),
    ProgresScreen(),
    _PlaceholderTabScreen(title: 'Riwayat Catatan Latihan'),
    _PlaceholderTabScreen(title: 'Feedback & Komunitas AI+PT'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bg,
      body: IndexedStack(
        index: _currentIndex,
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
                color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_outlined, label: 'Beranda'),
              _buildNavItem(index: 1, icon: Icons.sports, label: 'PT ku'),
              _buildNavItem(index: 2, icon: Icons.trending_up_rounded, label: 'Progres'),
              _buildNavItem(index: 3, icon: Icons.history_rounded, label: 'Riwayat'),
              _buildNavItem(index: 4, icon: Icons.chat_bubble_rounded, label: 'Feedback'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final Color activeColor = isSelected ? const Color(0xFFFF5520) : (context.isDark ? Colors.white : const Color(0xFF0E1714));
    final Color inactiveColor = context.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
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

class _PlaceholderTabScreen extends StatelessWidget {
  final String title;
  const _PlaceholderTabScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.surfaceInner,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.border),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Color(0xFFFF5520),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Modul ini sudah terhubung ke navigasi utama.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
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