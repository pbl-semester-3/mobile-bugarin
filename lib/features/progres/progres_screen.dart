import 'package:flutter/material.dart';

// TODO: implementasikan sesuai Bugarin_PRD_Mobile.md bab 3.5 — tab Olahraga (dropdown
// master_olahraga, field jarak kondisional) & tab Meal (preset + custom entry).
class ProgresScreen extends StatelessWidget {
  const ProgresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Olahraga'), Tab(text: 'Meal')]),
          const Expanded(
            child: TabBarView(
              children: [
                Center(child: Text('Tab Olahraga')),
                Center(child: Text('Tab Meal')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
