import 'package:cheapcheap/models/budget.dart';
import 'package:flutter/material.dart';

class BudgetStatsScreen extends StatelessWidget {
  const BudgetStatsScreen({super.key, required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget stats')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
