import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class BugarinLogo extends StatelessWidget {
  const BugarinLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background.withValues(alpha: 0.6),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: ShaderMask(
        shaderCallback: (rect) => AppColors.brandGradient.createShader(rect),
        child: Text(
          'B',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}