import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class AboutTile extends StatefulWidget {
  final String title;
  final String value;
  final bool copyable;
  final bool editable;
  final ValueChanged<String>? onSave;
  final String? Function(String value)? validator;

  const AboutTile({
    super.key,
    required this.title,
    required this.value,
    this.copyable = false,
    this.editable = false,
    this.onSave,
    this.validator,
  });

  @override
  State<AboutTile> createState() => _AboutTileState();
}

class _AboutTileState extends State<AboutTile> {
  bool _editing = false;
  String? _errorText;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AboutTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value && !_editing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();

    final error = widget.validator?.call(value);

    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    if (value.isNotEmpty && value != widget.value) {
      widget.onSave?.call(value);
    }

    setState(() {
      _editing = false;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: widget.copyable && !_editing
          ? () async {
              await Clipboard.setData(ClipboardData(text: widget.value));

              if (context.mounted) {
                CustomAppToast.show(
                  context: context,
                  message: l10n.copiedToClipboard,
                  type: ToastType.success,
                );
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _editing
                      ? CustomTextField(
                          controller: _controller,
                          hintText: widget.title,
                          errorText: _errorText,
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() {
                                _errorText = null;
                              });
                            }
                          },
                        )
                      : Text(
                          widget.value,
                          softWrap: true,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                ),

                if (widget.copyable && !_editing) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.content_copy,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],

                if (widget.editable) ...[
                  const SizedBox(width: 8),
                  CustomIconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: Icon(_editing ? Icons.check : Icons.edit),
                    onPressed: () {
                      if (_editing) {
                        _save();
                      } else {
                        setState(() {
                          _editing = true;
                          _errorText = null;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
