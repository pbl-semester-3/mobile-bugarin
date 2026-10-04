import 'package:flutter/material.dart';

import '../../core/theme/theme_provider.dart';

/// Layar singkat saat sesi auth masih dipulihkan (state [AuthUnknown]).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: const Center(
        child: SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            color: Color(0xFFFF5520),
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}
