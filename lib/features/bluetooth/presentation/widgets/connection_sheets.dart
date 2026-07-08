import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_button.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class PairingPinInputSheet extends StatefulWidget {
  final String deviceName;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  const PairingPinInputSheet({
    super.key,
    required this.deviceName,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<PairingPinInputSheet> createState() => _PairingPinInputSheetState();
}

class _PairingPinInputSheetState extends State<PairingPinInputSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.backgroundVariantDark,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.labelLarge,
                    children: [
                      TextSpan(text: '${l10n.enterCodeToConnect} '),
                      TextSpan(
                        text: widget.deviceName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CustomIconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 24),

          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              width: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {});
                  if (val.length == 6) {
                    widget.onSubmit(val);
                  }
                },
              ),
            ),
          ),

          // 6 PIN Boxes row
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final char = _controller.text.length > index
                    ? _controller.text[index]
                    : "";
                final isActive =
                    _focusNode.hasFocus &&
                    index == (_controller.text.length.clamp(0, 5));

                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive
                          ? AppColors.onSurface
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      char.isNotEmpty ? char : "-",
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: char.isNotEmpty
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariantDark,
                          ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class ConnectionCodeSheet extends StatelessWidget {
  final String deviceName;
  final String code;
  final VoidCallback onCancel;
  final VoidCallback onPair;

  const ConnectionCodeSheet({
    super.key,
    required this.deviceName,
    required this.code,
    required this.onCancel,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.backgroundVariantDark,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.connectionCode,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              CustomIconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Render code spaced out: e.g. "4  4  5  1  2  0"
          Center(
            child: Text(
              code.split('').join('    '),
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: l10n.cancel,
                  onPressed: onCancel,
                  backgroundColor: AppColors.onSurfaceVariantDark,
                  textColor: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  label: l10n.pair,
                  onPressed: onPair,
                  backgroundColor: AppColors.onSurface,
                  textColor: AppColors.surface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
