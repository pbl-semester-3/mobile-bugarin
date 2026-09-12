import 'package:flutter/material.dart';

// TODO: implementasikan sesuai Bugarin_PRD_Mobile.md bab 3.1 (nama, email, username, password).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: const Center(child: Text('Register Bugarin')),
    );
  }
}
