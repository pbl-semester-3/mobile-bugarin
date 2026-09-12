import 'package:flutter/material.dart';

// TODO: implementasikan sesuai Bugarin_PRD_Mobile.md bab 3.2 — form isi profil pertama kali
// (usia, jenis kelamin, alergi, tinggi badan, BB awal, tujuan, BB tujuan, durasi progres).
// Dipakai ulang juga untuk "Mulai Target Baru" (lihat skill gorouter-navigation-bugarin,
// dibedakan lewat query param `mode`).
class OnboardingScreen extends StatelessWidget {
  final String mode; // 'first-time' | 'new-cycle'
  const OnboardingScreen({this.mode = 'first-time', super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil')),
      body: const Center(child: Text('Onboarding Bugarin')),
    );
  }
}
