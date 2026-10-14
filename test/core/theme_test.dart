import 'package:bugarin_mobile/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tema gelap memakai palet Figma (netral + oranye FF5C39)',
      (tester) async {
    late Color bg, card, surfaceInner, border, textPrimary, textSecondary;
    late Color primary;

    await tester.pumpWidget(
      MaterialApp(
        theme: bugarinDarkTheme,
        home: Builder(
          builder: (context) {
            bg = context.bg;
            card = context.card;
            surfaceInner = context.surfaceInner;
            border = context.border;
            textPrimary = context.textPrimary;
            textSecondary = context.textSecondary;
            primary = context.primary;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(bg, const Color(0xFF0E0E10));
    expect(card, const Color(0xFF201F1F));
    expect(surfaceInner, const Color(0xFF2A2A2A));
    expect(border, const Color(0xFF2A2A2A));
    expect(textPrimary, const Color(0xFFFAF8FF));
    expect(textSecondary, const Color(0xFFA1A1AA));
    expect(primary, const Color(0xFFFF5C39));
    expect(bugarinDarkTheme.colorScheme.primary, const Color(0xFFFF5C39));
    expect(bugarinDarkTheme.scaffoldBackgroundColor, const Color(0xFF0E0E10));
  });
}
