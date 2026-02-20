import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}
