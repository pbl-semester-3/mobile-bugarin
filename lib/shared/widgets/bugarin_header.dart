import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/profil/profil_screen.dart';

class BugarinHeader extends StatelessWidget {
  final String subtitle;
  final Widget? trailingBadge;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showProfileAvatar;

  const BugarinHeader({
    super.key,
    required this.subtitle,
    this.trailingBadge,
    this.showBackButton = false,
    this.onBack,
    this.showProfileAvatar = true,
  });

  void _showNotificationSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pemberitahuan',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Tandai sudah dibaca',
                    style: TextStyle(
                      color: Color(0xFFFF5520),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceInner,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1A2E27) : const Color(0xFFFFECE5),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFFF5520),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesi Latihan Hari Ini',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Coach Sarah Jenkins menjadwalkan sesi jam 16:30 WIB.',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showBackButton) ...[
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceInner,
                    border: Border.all(color: context.border, width: 1.2),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.card,
                border: Border.all(
                  color: const Color(0xFFFF5520),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'B',
                  style: TextStyle(
                    color: Color(0xFFFF5520),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUGARIN',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (trailingBadge != null) ...[
              trailingBadge!,
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: () => _showNotificationSheet(context, isDark),
              icon: Icon(
                Icons.notifications_none_rounded,
                color: context.textPrimary,
                size: 22,
              ),
            ),
            if (showProfileAvatar) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilScreen()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.border,
                      width: 1.5,
                    ),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}