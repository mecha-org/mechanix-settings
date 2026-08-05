import 'package:flutter/material.dart';

class SettingsInfoRow extends StatefulWidget {
  final String title;
  final String value;
  final bool obscureValue;

  const SettingsInfoRow({
    super.key,
    required this.title,
    required this.value,
    this.obscureValue = false,
  });

  @override
  State<SettingsInfoRow> createState() => _SettingsInfoRowState();
}

class _SettingsInfoRowState extends State<SettingsInfoRow> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureValue;
  }

  @override
  void didUpdateWidget(covariant SettingsInfoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureValue != widget.obscureValue) {
      _obscured = widget.obscureValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _obscured ? '•' * widget.value.length.clamp(0, 16) : widget.value;

    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(widget.title, style: Theme.of(context).textTheme.labelLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayValue,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (widget.obscureValue) ...[
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                _obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscured = !_obscured;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
