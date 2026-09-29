import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Daftar halaman untuk setiap tab (Beranda, Pelatih, Progress, Riwayat, Feedback)
  final List<Widget> _pages = const [
    DashboardScreen(),
    _PlaceholderTabScreen(title: 'Sesi Bersama Pelatih'),
    _PlaceholderTabScreen(title: 'Progress Transformasi Fisik'),
    _PlaceholderTabScreen(title: 'Riwayat Catatan Latihan'),
    _PlaceholderTabScreen(title: 'Feedback & Komunitas AI+PT'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E0C),
      // IndexedStack menjaga agar halaman tidak reload dari awal saat berpindah tab
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // FOOTER KAPSUL MELAYANG PERSIS SEPERTI DESAIN ASLI
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1C18), // Warna dasar Deep Pine
            borderRadius: BorderRadius.circular(36), // Bentuk kapsul melingkar penuh
            border: Border.all(
              color: const Color(0xFF1B2F28), // Garis pinggir halus
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                label: 'Beranda',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.sports, // Ikon peluit resmi pelatih
                label: 'Pelatih',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.trending_up_rounded,
                label: 'Progress',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.history_rounded,
                label: 'Riwayat',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.chat_bubble_rounded,
                label: 'Feedback',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET ITEM NAVIGASI DENGAN INDIKATOR WARNA ELEGAN (BUKAN NEON)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    // Saat aktif: Putih bersih (#FFFFFF). Saat tidak aktif: Abu-abu lembut (#70827A)
    final Color activeColor = Colors.white;
    final Color inactiveColor = const Color(0xFF70827A);

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
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
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

// Layar sementara yang rapi untuk tab lain sebelum disambungkan ke modulnya masing-masing
class _PlaceholderTabScreen extends StatelessWidget {
  final String title;
  const _PlaceholderTabScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E0C),
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
                    color: const Color(0xFF111E19),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1B2F28)),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Color(0xFF3EE5B4),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Modul ini sudah terhubung ke navigasi utama.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF70827A),
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