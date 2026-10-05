import 'package:flutter/foundation.dart';

/// Tab aktif pada MainShell (0 = Beranda, 1 = PT ku, 2 = Progres,
/// 3 = Riwayat, 4 = Feedback).
///
/// Layar mana pun dapat berpindah tab dengan mengubah nilainya, misalnya:
///   shellTabIndex.value = 1; // buka tab PT ku
final ValueNotifier<int> shellTabIndex = ValueNotifier<int>(0);