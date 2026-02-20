import 'package:flutter/material.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(child: Text('No reports available.')),
    );
  }
}
