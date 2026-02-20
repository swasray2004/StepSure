import 'package:flutter/material.dart';
import '../../../domain/models/session_model.dart';

class ResultsScreen extends StatelessWidget {
  final SessionModel session;
  final Map<String, dynamic> report;

  const ResultsScreen({super.key, required this.session, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child:
            Text('Session ID: \\${session.id}\nReport: \\${report.toString()}'),
      ),
    );
  }
}
