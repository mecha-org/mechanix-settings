import 'package:flutter/material.dart';

class EnterpriseRow extends StatelessWidget {
  final String label;
  final Widget child;

  const EnterpriseRow({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
