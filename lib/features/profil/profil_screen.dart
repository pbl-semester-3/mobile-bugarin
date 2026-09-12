import 'package:flutter/material.dart';

// TODO: implementasikan sesuai Bugarin_PRD_Mobile.md bab 3.8 — 4 form section
// (Informasi Diri, Detail Penting + banner "Mulai Target Baru", Password, Tema),
// tiap section submit independen (lihat skill flutter-form-validation).
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(child: Text('Profil Bugarin')),
    );
  }
}
