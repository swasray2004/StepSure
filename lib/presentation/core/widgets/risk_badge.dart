import 'package:flutter/material.dart';

class RiskBadge extends StatelessWidget {
  final String risk;
  final bool large;
  const RiskBadge({super.key, required this.risk, this.large = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (risk.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 8, vertical: large ? 8 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(large ? 16 : 8),
        border: Border.all(color: color),
      ),
      child: Text(
        risk.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: large ? 16 : 12,
        ),
      ),
    );
  }
}
