import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  final dynamic report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Detail')),
      body: Center(child: Text('Report details go here.')),
    );
  }
}
