import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/progres/progres_screen.dart';
import '../features/pt_ku/pt_ku_screen.dart';
import '../features/riwayat/riwayat_screen.dart';
import 'shell_tab.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const int _indexFeedback = 4;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    shellTabIndex.value = 0; // selalu mulai dari Beranda
    shellTabIndex.addListener(_onTabDiubah);
  }

  @override
  void dispose() {
    shellTabIndex.removeListener(_onTabDiubah);
    super.dispose();
  }
  void _onTabDiubah() {
    final baru = shellTabIndex.value;
    if (mounted && baru != currentIndex) {
      setState(() => currentIndex = baru);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final unreadFeedback = ref.watch(feedbackUnreadCountProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: IndexedStack(
        index: currentIndex,
        children: [
          const DashboardScreen(),
          const PtKuScreen(),
          const ProgresScreen(),
          const RiwayatScreen(),
          FeedbackScreen(isActive: currentIndex == _indexFeedback),
        ],
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
              buildNavItem(
                index: _indexFeedback,
                icon: Icons.chat_bubble_rounded,
                label: 'Feedback',
                badgeCount: unreadFeedback,
              ),
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
    int badgeCount = 0,
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
          onTap: () => shellTabIndex.value = index,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
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
                    if (badgeCount > 0)
                      Positioned(
                        top: -5,
                        right: -9,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5520),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.card, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
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